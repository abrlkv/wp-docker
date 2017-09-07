<?php
/*
!!!REPLASE "themename" 
*/

//require_once __DIR__.'/inc/custom_posts.php';
require_once __DIR__.'/inc/cur-to-lat.php';
//require_once __DIR__.'/inc/theme_options.php';
//require_once __DIR__.'/inc/acf.php';

//load css styles and js scripts
function themename_scripts() {
	//load css
	wp_enqueue_style( 'mainstyles', get_template_directory_uri() . '/css/main.min.css' );
	//load scripts
	wp_enqueue_script('scripts', get_template_directory_uri() . '/js/scripts.min.js', array('jquery'), false, true);
}
add_action( 'wp_enqueue_scripts', 'themename_scripts' );

//
add_action('after_setup_theme', 'themename_load_theme_textdomain');
 
function themename_load_theme_textdomain(){
	load_theme_textdomain( 'themename', get_template_directory() . '/languages' );
}

if ( function_exists( 'add_theme_support' ) )
add_theme_support( 'post-thumbnails' );
add_theme_support('menus');

register_nav_menus( array(
	'main-menu' => 'Меню',
) );
set_post_thumbnail_size(150, 150);
add_image_size( 'news-archive-thumbnail', 370, 236, true );