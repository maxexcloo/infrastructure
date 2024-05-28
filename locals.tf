locals {
  cloudflare_records_merged = {
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
    for k, v in restapi_object.server_resend_key : k => {
      api_key = jsondecode(v.create_response).token
    }
  }

  routers = merge({
    for i, router in var.routers : "${router.location}.${var.default.domain}" => merge(
      router,
      {
        fqdn        = "${router.location}.${var.default.domain}"
        host        = router.location
        name        = router.location
        parent_name = ""
        parent_type = ""
        tags        = concat(["router"], try(router.tags, []))
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
      for i, server in var.servers_mac : "${server.name}.${router.location}.${var.default.domain}" => merge(
        server,
        {
          fqdn        = "${server.name}.${router.location}.${var.default.domain}"
          host        = "${router.location}-${server.name}"
          location    = router.location
          parent_name = router.name
          parent_type = router.type
          tags        = concat(["server"], try(router.tags, []))
          type        = "mac"
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router["${router.location}.${var.default.domain}"].name
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
    local.vms_mac,
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
      for i, server in var.servers_proxmox : "${server.name}.${router.location}.${var.default.domain}" => merge(
        server,
        {
          fqdn        = "${server.name}.${router.location}.${var.default.domain}"
          host        = "${router.location}-${server.name}"
          location    = router.location
          parent_name = router.name
          parent_type = router.type
          tags        = concat(["server"], try(server.tags, []))
          type        = "proxmox"
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router["${router.location}.${var.default.domain}"].name
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

  ssh_keys_merged = {
    for k, v in tls_private_key.server_ssh_key : k => {
      private_key = trimspace(nonsensitive(v.private_key_openssh))
      public_key  = trimspace(v.public_key_openssh)
    }
  }

  tailscale_keys_merged = {
    for k, v in merge(tailscale_tailnet_key.docker, tailscale_tailnet_key.server) : k => {
      key = nonsensitive(v.key)
    }
  }

  vms_mac = merge([
    for i, server in local.servers_mac : {
      for i, vm in var.vms_mac : "${server.name}-${vm.name}.${server.location}.${var.default.domain}" => merge(
        vm,
        {
          fqdn        = "${server.name}-${vm.name}.${server.location}.${var.default.domain}"
          host        = "${server.location}-${server.name}-${vm.name}"
          location    = server.location
          parent_name = server.name
          parent_type = server.type
          tags        = concat(["vm"], try(vm.tags, []))
          config = merge(
            {
              packages = []
              timezone = var.default.timezone
            },
            try(vm.config, {})
          )
          network = merge(
            {
              mac_address     = upper(macaddress.server_mac[i].address)
              private_address = ""
              public_address  = cloudflare_record.router["${server.location}.${var.default.domain}"].name
              ssh_port        = 22
            },
            try(vm.network, {})
          )
          provider = merge(
            {
              host     = server.host
              path     = "${server.config.vms_path}/${vm.name}"
              port     = server.network.ssh_port
              username = server.user.username
            },
            try(server.config, {})
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

  vms_oci = merge({
    for i, vm in var.vms_oci : "${vm.name}.${vm.location}.${var.default.domain}" => merge(
      vm,
      {
        fqdn        = "${vm.name}.${vm.location}.${var.default.domain}"
        host        = "${vm.location}-${vm.name}"
        parent_name = "oci"
        parent_type = "cloud"
        tags        = concat(["vm"], try(vm.tags, []))
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
      for i, vm in var.vms_proxmox : "${server.name}-${vm.name}.${server.location}.${var.default.domain}" => merge(
        vm,
        {
          fqdn        = "${server.name}-${vm.name}.${server.location}.${var.default.domain}"
          host        = "${server.location}-${server.name}-${vm.name}"
          location    = server.location
          parent_name = server.name
          parent_type = server.type
          tags        = concat(["vm"], try(vm.tags, []))
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
              public_address  = cloudflare_record.router["${server.location}.${var.default.domain}"].name
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

  tags = distinct(concat(
    ["docker"],
    [
      for i, v in local.servers_merged : v.tags[0]
    ]
  ))

  websites = merge([
    for zone, websites in var.websites : {
      for i, website in websites : "${website.name}.${zone}" => merge(
        website,
        {
          zone = zone
        }
      )
    }
  ]...)

  websites_merged_openwrt = merge([
    for k, server in local.servers_merged_cloudflare : {
      for i, website in local.cloudflare_records_merged : i => {
        fqdn     = website.hostname
        host     = server.host
        location = server.location
      }
      if server.fqdn == website.hostname || server.fqdn == website.value
    }
  ]...)

  zones = merge(
    var.dns,
    var.websites
  )
}
