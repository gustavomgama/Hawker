# Run using bin/ci

CI.run "Continuous Integration", "Autoloading, style, security, i18n, and code quality" do
  step "Code: Autoloading", "ruby", "bin/rails", "zeitwerk:check"

  step "Style: Ruby", "ruby", "bin/rubocop"

  step "Security: Brakeman", "ruby", "bin/brakeman", "--quiet", "--no-pager", "--exit-on-warn", "--exit-on-error"
  step "Security: Gem audit", "ruby", "bin/bundler-audit", "check", "--update"

  step "I18n: Missing translations", "ruby", "bin/i18n-tasks", "missing"

  step "Quality: RubyCritic", "ruby", "bin/rubycritic", "--no-browser", "--format", "html", "--path", "tmp/rubycritic", "app", "lib", "config"
end
