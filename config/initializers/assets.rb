# config/initializers/assets.rb
# Be sure to restart your server when you modify this file.
assets = Rails.application.config.assets
# Enable the asset pipeline
assets.enabled = true
#assets.quiet = true
assets.compress = true
#config.assets.precompile << /(^[^_\/]|\/[^_])[^\/]*$/
#config.assets.precompile += ['ckeditor/*']
#config.assets.check_precompiled_asset = false
# Version of your assets, change this if you want to expire all your assets
assets.version = '1.0'

#assets.unknown_asset_fallback = false
#config.assets.precompile += %w(creative/manifest.js creative/manifest.css images/* fonts/* stylesheets/* javascripts/*)
assets.paths << Rails.root.join("app", "assets", "fonts")

#assets.configure do |env|
#  env.context_class.class_eval do
#    include AppsHelper
#  end
#end

# TODO: o sistema usa include_tags de js e css em varios lugares.
#       E isso precisa ser corrigido. Enquanto isso segue um "workaround":
Rails.application.config.assets.precompile += %w[academic_allocation_user.js administrations.js allocations.js application.js assignment_webconferences.js assignments.js audios.js autocomplete.js bibliographies.js bibliography_authors.js breadcrumb.js calendar.js chat_rooms.js ckeditor/init.js comments.js contextual_help/discussion.js contextual_help/discussion_posts.js contextual_help/home.js contextual_help/lessons.js contextual_help/subject.js contextual_help/support_material.js courses.js digital_classes.js discussions.js edition.js edition_discussions.js enrollments.js exams.js fullcalendar.js group_assignments.js groups.js groups_tags.js ie-warning.js ip.js jquery-3.3.1.min.js jquery-ui-1.8.6.js jquery-ui-timepicker-addon.js jquery-ui.js jquery.cookie.js jquery.dropdown.js jquery.fancybox3.min.js jquery.js jquery.mask.js jquery.qtip.min.js jquery.tokeninput.js jquery.ui.datepicker-en-US.js jquery.ui.datepicker-pt-BR.js jspanel.js jspdf.min.js lesson_files.js lesson_notes.js lessons.js login.js lte-ie7 lte-ie7.js messages.js multiple_file_upload.js notifications.js online_correction_files.js pagination.js pdfjs/pdf.js portlet_slider.js profiles.js questions.js registrations.js respond.min.js schedule_event_files.js schedule_events.js scores.js shortcut.js social_networks.js tableHeadFixer.js tablesorter.js tooltip.js user_blacklist.js webconferences.js zoom/jquery.zoom.js]
Rails.application.config.assets.precompile += %w[themes/theme_blue.css themes/theme_red.css themes/theme_high_contrast.css autocomplete.css fancyBox.css fonts/fonts-ie.css fonts/fonts.css fonts/icons.css fullcalendar.css.css jquery-ui-timepicker-addon.css jquery.dropdown.css.css jquery.fancybox3.min.css jquery.qtip.min.css login.css misc/div_layout.css misc/facebook.css misc/ie7.css online_correction_files.css pdf.css ui.dynatree.custom.css viewer.css]
