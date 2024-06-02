locals {
  b2_buckets = {
    for k, v in b2_bucket.website : k => {
      application_key    = nonsensitive(b2_application_key.website[k].application_key)
      application_key_id = b2_application_key.website[k].application_key_id
      bucket_name        = v.bucket_name
      endpoint           = data.b2_account_info.default.s3_api_url
    }
  }

  cloudflare_records_merged = merge(
    {
      for k, v in cloudflare_record.internal : "${k}-internal" => v
    },
    {
      for k, v in merge(
        cloudflare_record.dns,
        cloudflare_record.router,
        cloudflare_record.server,
        cloudflare_record.vm_oci_ipv4,
        cloudflare_record.vm_oci_ipv6,
        cloudflare_record.website
      ) : k => v
      if v.type == "A" || v.type == "AAAA" || v.type == "CNAME"
    }
  )

  cloudflare_tunnels = {
    for k, v in cloudflare_tunnel.server : k => {
      tunnel_token = nonsensitive(v.tunnel_token)
    }
  }

  dns = merge([
    for zone, records in var.dns : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        record,
        {
          zone = zone
        }
      )
    }
  ]...)

  resend_keys_merged = {
    for k, v in merge(restapi_object.server_resend_key, restapi_object.website_resend_key) : k => {
      api_key = jsondecode(v.create_response).token
    }
  }

  routers = merge({
    for i, router in var.routers : router.location => merge(
      router,
      {
        fqdn_external = "${router.location}.${var.default.domain}"
        fqdn_internal = "${router.location}.int.${var.default.domain}"
        host          = router.location
        name          = router.location
        parent_name   = ""
        parent_type   = ""
        tags          = concat(["router"], try(router.tags, []))
        network = merge(
          {
            mac_address     = ""
            private_address = ""
            public_address  = ""
            ssh_port        = 22
          },
          try(router.network, {})
        )
        provider = merge(
          {
            port = 81
          },
          var.terraform.openwrt[router.location]
        )
        user = merge(
          {
            automation = "root"
            fullname   = ""
            ssh_keys   = data.github_user.default.ssh_keys
            username   = "root"
          },
          try(router.user, {})
        )
      }
    )
  })

  servers_mac = merge([
    for i, router in local.routers : {
      for i, server in var.servers_mac : "${router.location}-${server.name}" => merge(
        server,
        {
          fqdn_external = "${server.name}.${router.location}.${var.default.domain}"
          fqdn_internal = "${server.name}.${router.location}.int.${var.default.domain}"
          host          = "${router.location}-${server.name}"
          location      = router.location
          parent_name   = router.name
          parent_type   = router.type
          tags          = concat(["server"], try(router.tags, []))
          type          = "mac"
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router[router.location].name
              ssh_port        = 22
            },
            try(server.network, {})
          )
          user = merge(
            {
              automation = "root"
              fullname   = ""
              ssh_keys   = data.github_user.default.ssh_keys
              username   = "root"
            },
            try(server.user, {})
          )
        },
      )
      if server.parent == router.name
    }
  ]...)

  servers_merged = merge(
    local.routers,
    local.servers_mac,
    local.servers_proxmox,
    local.vms_oci,
    local.vms_proxmox
  )

  servers_merged_cloudflare = {
    for k, v in local.servers_merged : k => v
    if v.parent_type != "cloud" && v.tags[0] != "router"
  }

  servers_merged_ssh = {
    for k, v in local.servers_merged : k => v
    if v.tags[0] == "server"
  }

  servers_proxmox = merge([
    for i, router in local.routers : {
      for i, server in var.servers_proxmox : "${router.location}-${server.name}" => merge(
        server,
        {
          fqdn_external = "${server.name}.${router.location}.${var.default.domain}"
          fqdn_internal = "${server.name}.${router.location}.int.${var.default.domain}"
          host          = "${router.location}-${server.name}"
          location      = router.location
          parent_name   = router.name
          parent_type   = router.type
          tags          = concat(["server"], try(server.tags, []))
          type          = "proxmox"
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router[router.location].name
              ssh_port        = 22
            },
            try(server.network, {})
          )
          provider = merge(
            {
              api_token = var.terraform.proxmox[server.name].api_token
              insecure  = try(var.terraform.proxmox[server.name].insecure, true)
              port      = try(var.terraform.proxmox[server.name].port, 8006)
            },
            try(server.provider, {})
          )
          user = merge(
            {
              automation = "root"
              fullname   = ""
              ssh_keys   = data.github_user.default.ssh_keys
              username   = "root"
            },
            try(server.user, {})
          )
        },
      )
      if server.parent == router.name
    }
  ]...)

  ssh_keys = {
    for k, v in tls_private_key.server_ssh_key : k => {
      private_key = trimspace(nonsensitive(v.private_key_openssh))
      public_key  = trimspace(v.public_key_openssh)
    }
  }

  tags = {
    for i, tag in var.tags : tag.name => merge(
      {
        tailscale_tag = "tag:${tag.name}"
      },
      tag
    )
  }

  tailscale_keys_merged = {
    for k, v in merge(tailscale_tailnet_key.server, tailscale_tailnet_key.website) : k => {
      tailnet_key = nonsensitive(v.key)
    }
  }

  vms_oci = merge({
    for i, vm in var.vms_oci : "${vm.location}-${vm.name}" => merge(
      vm,
      {
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain}"
        fqdn_internal = "${vm.name}.${vm.location}.int.${var.default.domain}"
        host          = "${vm.location}-${vm.name}"
        parent_name   = "oci"
        parent_type   = "cloud"
        tags          = concat(["vm"], try(vm.tags, []))
        config = merge(
          {
            packages = []
            timezone = var.default.timezone
          },
          try(vm.config, {})
        )
        network = merge(
          {
            private_address = ""
            ssh_port        = 22
          },
          try(vm.network, {})
        )
        user = merge(
          {
            automation = "root"
            fullname   = ""
            ssh_keys   = data.github_user.default.ssh_keys
            username   = "root"
          },
          try(vm.user, {})
        )
      }
    )
  })

  vms_proxmox = merge([
    for i, server in local.servers_proxmox : {
      for i, vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        vm,
        {
          fqdn_external = "${server.name}-${vm.name}.${server.location}.${var.default.domain}"
          fqdn_internal = "${server.name}-${vm.name}.${server.location}.int.${var.default.domain}"
          host          = "${server.location}-${server.name}-${vm.name}"
          location      = server.location
          name          = "${server.name}-${vm.name}"
          parent_name   = server.name
          parent_type   = server.type
          tags          = concat(["vm"], try(vm.tags, []))
          config = merge(
            {
              boot_image_url = ""
              packages       = ["qemu-guest-agent"]
              timezone       = var.default.timezone
            },
            try(vm.config, {})
          )
          network = merge(
            {
              private_address = ""
              public_address  = cloudflare_record.router[server.location].name
              ssh_port        = 22
            },
            try(vm.network, {})
          )
          user = merge(
            {
              automation = "root"
              fullname   = ""
              ssh_keys   = data.github_user.default.ssh_keys
              username   = "root"
            },
            try(vm.user, {})
          )
        },
      )
      if vm.parent == server.name
    }
  ]...)

  websites = merge([
    for zone, websites in var.websites : {
      for i, website in websites : "${website.name}.${zone}" => merge(
        {
          app_name      = website.name
          b2_bucket     = false
          fly_app       = false
          fqdn_external = "${website.name}.${zone}"
          group         = "Websites"
          password      = false
          resend_key    = false
          tailscale_key = false
          type          = "default"
          username      = null
          zone          = zone
        },
        website
      )
    }
  ]...)

  websites_merged_openwrt = merge([
    for k, server in local.servers_merged_cloudflare : {
      for i, website in local.cloudflare_records_merged : i => {
        fqdn_external = website.hostname
        host          = server.host
        location      = server.location
      }
      if server.fqdn_external == website.hostname || server.fqdn_external == website.value
    }
  ]...)

  zones = merge(
    var.dns,
    var.websites
  )
}
