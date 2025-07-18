require 'spec_helper'

provider_class = Puppet::Type.type(:apache_setenv).provider(:augeas)

describe provider_class do
  before do
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(FileTest).to receive(:exist?).with('/etc/apache2/apache2.conf').and_return(true)
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:apache_setenv).new(
               name: 'TEST',
               value: 'test',
               ensure: 'present',
               target: target,
               provider: 'augeas'
             ))

      augparse(target, 'Httpd.lns', '{ "directive" = "SetEnv" { "arg" = "TEST" } { "arg" = "test" } }')
    end
  end

  context 'with full file' do
    let(:tmptarget) { aug_fixture('full') }
    let(:target) { tmptarget.path }

    it 'lists instances' do
      allow(provider_class).to receive(:target).and_return(target)
      inst = provider_class.instances.map do |p|
        {
          name: p.get(:name),
          ensure: p.get(:ensure),
          value: p.get(:value)
        }
      end

      expect(inst.size).to eq(2)
      expect(inst[0]).to eq({ name: 'TEST', ensure: :present, value: 'test' })
      expect(inst[1]).to eq({ name: 'TEST2', ensure: :present, value: :absent })
    end
  end

  context 'with simple file' do
    let(:tmptarget) { aug_fixture('simple') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:apache_setenv).new(
               name: 'FOO',
               value: 'test',
               ensure: 'present',
               target: target,
               provider: 'augeas'
             ))

      # New entry gets added next to existing SetEnv entries
      augparse(target, 'Httpd.lns', '
        { "directive" = "SetEnv" { "arg" = "TEST" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "ignored" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "test.com" } }
        { "directive" = "SetEnv" { "arg" = "FOO" } { "arg" = "test" } }
        { "directive" = "Example" }
      ')
    end

    describe 'when update existing' do
      it 'updates existing' do
        apply!(Puppet::Type.type(:apache_setenv).new(
                 name: 'FQDN',
                 value: 'test2.com',
                 ensure: 'present',
                 target: target,
                 provider: 'augeas'
               ))

        # Should have deleted the second FQDN entry
        aug_open(target, 'Httpd.lns') do |aug|
          expect(aug.match("directive[.='SetEnv' and arg[1]='FQDN']").size).to eq(1)
        end

        augparse(target, 'Httpd.lns', '
          { "directive" = "SetEnv"
            { "arg" = "TEST" }
          }
          { "directive" = "SetEnv"
            { "arg" = "FQDN" }
            { "arg" = "test2.com" }
          }
          { "directive" = "Example" }
        ')
      end

      it 'clears value when no value' do
        apply!(Puppet::Type.type(:apache_setenv).new(
                 name: 'FQDN',
                 value: '',
                 ensure: 'present',
                 target: target,
                 provider: 'augeas'
               ))
        augparse(target, 'Httpd.lns', '
          { "directive" = "SetEnv" { "arg" = "TEST" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } }
          { "directive" = "Example" }
        ')
      end
    end

    it 'deletes entries' do
      apply!(Puppet::Type.type(:apache_setenv).new(
               name: 'FQDN',
               ensure: 'absent',
               target: target,
               provider: 'augeas'
             ))

      augparse(target, 'Httpd.lns', '
        { "directive" = "SetEnv"
          { "arg" = "TEST" }
        }
        { "directive" = "Example" }
      ')
    end
  end

  context 'with broken file' do
    let(:tmptarget) { aug_fixture('broken') }
    let(:target) { tmptarget.path }

    it 'fails to load' do
      txn = apply(Puppet::Type.type(:apache_setenv).new(
                    name: 'FQDN',
                    value: 'test.com',
                    ensure: 'present',
                    target: target,
                    provider: 'augeas'
                  ))

      expect(txn.any_failed?).not_to be_nil
      expect(@logs.first.level).to eq(:err)
      expect(@logs.first.message).to include(target)
    end
  end
end
