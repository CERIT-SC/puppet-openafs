class openafs::client::config (
  $enabled,
  $afsdb,
  $crypt,
  $dynroot,
  $fakestat,
  $options,
  $mount_dir,
  $cache_dir,
  $cacheinfo,
  $export_cell,
  $this_cell,
  $these_cells,
  $post_init,
  $pam_afs_session_args,
  $fn_this_cell,
  $fn_these_cells,
  $fn_cell_serv_db,
  $cell_serv_db_source,
  $fn_cacheinfo,
  $fn_post_init
) {
  file { $mount_dir:
    ensure => directory,
  }

  if $cache_dir {
    file { $cache_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }
  }

  if $fn_this_cell and $this_cell {
    file { $fn_this_cell:
      ensure  => file,
      content => "${this_cell}\n",
    }
  }

  if $fn_these_cells and $these_cells {
    file { $fn_these_cells:
      ensure  => file,
      content => join(flatten($these_cells), "\n"),
    }
  }

  if $fn_cacheinfo and $cacheinfo {
    file { $fn_cacheinfo:
      ensure  => file,
      content => inline_template($cacheinfo),
    }
  }

  if $fn_cell_serv_db and $cell_serv_db_source {
    file { $fn_cell_serv_db:
      ensure => file,
      source => $cell_serv_db_source,
    }
  }

  # un/export AFS cell from env.
  $_ensure_export_cell = $export_cell ? {
    true    => file,
    default => absent,
  }

  file { '/etc/profile.d/afs.sh':
    ensure  => $_ensure_export_cell,
    content => "export CELL='${this_cell}'",
  }

  # concatenated post init hooks
  if $fn_post_init {
    concat { $fn_post_init:
      ensure => present,
      mode   => '0755',
    }

    openafs::client::post_init { 'header':
      fn_post_init => $fn_post_init,
      order        => 0,
      content      => '#!/bin/bash
# This file is generated by Puppet
',
    }

    if $post_init {
      openafs::client::post_init { 'custom':
        fn_post_init => $fn_post_init,
        order        => 99,
        content      => $post_init,
      }
    }
  }
}
