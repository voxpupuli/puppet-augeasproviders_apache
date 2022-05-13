# frozen_string_literal: true

dir = __dir__

require 'augeas_spec'

# augeasproviders: setting $LOAD_PATH to work around broken type autoloading'
$LOAD_PATH.unshift(
  dir,
  File.join(dir, 'fixtures/modules/augeasproviders_core/spec/lib'),
  File.join(dir, 'fixtures/modules/augeasproviders_core/lib')
)
