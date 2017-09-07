<?php
if( function_exists('acf_add_options_page') ) {
	acf_add_options_page(array(
		'page_title' 	=> 'Настройки темы',
		'menu_title' 	=> 'Настройки темы',
		'menu_slug' 	=> 'theme-options',
		'capability' 	=> 'manage_options',
		'redirect' 	=> true
	));
}