# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'apache_directive and apache_setenv' do
  before(:all) do
    shell("printf 'ServerName foo.example.com\\n<IfModule mpm_prefork_module>\\n    StartServers 2\\n</IfModule>\\n' > /tmp/apache_test.conf")
  end

  context 'with ensure => present' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<~PUPPET
          apache_directive { 'Timeout':
            ensure => present,
            args   => '60',
            target => '/tmp/apache_test.conf',
          }
          apache_directive { 'StartServers for mpm_prefork_module':
            ensure  => present,
            name    => 'StartServers',
            context => 'IfModule[arg="mpm_prefork_module"]',
            args    => '4',
            target  => '/tmp/apache_test.conf',
          }
          apache_setenv { 'SPECIAL_PATH':
            ensure => present,
            value  => '/foo/bin',
            target => '/tmp/apache_test.conf',
          }
        PUPPET
      end
    end

    describe file('/tmp/apache_test.conf') do
      its(:content) { is_expected.to match(%r{^ServerName foo\.example\.com$}) }
      its(:content) { is_expected.to match(%r{^Timeout 60$}) }
      its(:content) { is_expected.to match(%r{^<IfModule mpm_prefork_module>\n\s+StartServers 4\n</IfModule>$}) }
      its(:content) { is_expected.to match(%r{^SetEnv SPECIAL_PATH /foo/bin$}) }
    end
  end

  context 'with ensure => absent' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<~PUPPET
          apache_directive { 'ServerName':
            ensure => absent,
            args   => 'foo.example.com',
            target => '/tmp/apache_test.conf',
          }
          apache_setenv { 'SPECIAL_PATH':
            ensure => absent,
            target => '/tmp/apache_test.conf',
          }
        PUPPET
      end
    end

    describe file('/tmp/apache_test.conf') do
      its(:content) { is_expected.not_to match(%r{ServerName}) }
      its(:content) { is_expected.not_to match(%r{SPECIAL_PATH}) }
      its(:content) { is_expected.to match(%r{^Timeout 60$}) }
    end
  end
end
