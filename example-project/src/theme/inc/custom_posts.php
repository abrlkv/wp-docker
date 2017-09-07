<?php
function theme_posts_type(){
  $args_programs = array(
    'label'         => 'Программа передач',
    'public'             => true,
    'show_ui'            => true,
    'show_in_menu'       => true,
    'query_var'          => true,
    'rewrite'            => array( 'slug' => 'program' ),
    'map_meta_cap'       => true,
    'has_archive'        => true,
    'hierarchical'       => false,
    'menu_icon' => 'dashicons-calendar-alt',
    'menu_position'      => null,
    'supports'           => array( 'title' ),
  );

  register_post_type( 'programs', $args_programs );

}
add_action( 'init', 'theme_posts_type' );