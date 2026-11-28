# Run using bin/ci

ENV["RAILS_ENV"] = "test"

CI.run "Continuous Integration", "Locked gems, autoloading, schema, style, tests, security, i18n, and code quality" do
  step "Deps: Locked", "bundle", "check"
  step "Code: Autoloading", "ruby", "bin/rails", "zeitwerk:check"
  step "DB: Test schema", "ruby", "bin/rails", "db:test:prepare"
  step "DB: Migrate", "ruby", "bin/rails", "db:migrate"
  step "DB: Schema committed", "git", "diff", "--exit-code", "--", "db/schema.rb"

  step "Style: Ruby", "ruby", "bin/rubocop"
  step "Tests: MiniTest", "ruby", "bin/rails", "test"

  step "Security: Brakeman", "ruby", "bin/brakeman", "--quiet", "--no-pager", "--exit-on-warn", "--exit-on-error"
  step "Security: Gem audit", "ruby", "bin/bundler-audit", "check", "--update"
  step "Security: Importmap audit", "ruby", "bin/importmap", "audit"

  step "I18n: Missing translations", "ruby", "bin/i18n-tasks", "missing"
  step "I18n: Unused translations", "ruby", "bin/i18n-tasks", "unused"

  step "Quality: RubyCritic", "ruby", "bin/rubycritic", "--no-browser", "--format", "html", "--path", "tmp/rubycritic", "app", "lib", "config"
end
