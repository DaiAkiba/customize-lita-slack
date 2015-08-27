require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/get_user_files_handler"

# メッセージは日本語に固定
I18n.default_locale = :ja
I18n.locale = :ja

Lita::Handlers::GetUserFilesHandler.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
