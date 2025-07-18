require 'spec_helper'

provider_class = Puppet::Type.type(:apache_directive).provider(:augeas)

describe provider_class do
  before do
    allow(FileTest).to receive(:exist?).and_return(false)
    allow(Facter.fact(:osfamily)).to receive(:value).and_return('Debian')
    allow(FileTest).to receive(:exist?).with('/etc/apache2/apache2.conf').and_return(true)
  end

  context 'with empty file' do
    let(:tmptarget) { aug_fixture('empty') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:apache_directive).new(
               name: 'StartServers',
               args: '3',
               ensure: 'present',
               target: target,
               provider: 'augeas'
             ))

      augparse(target, 'Httpd.lns', '{ "directive" = "StartServers" { "arg" = "3" } }')
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
          args: p.get(:args),
          context: p.get(:context)
        }
      end

      expect(inst.size).to eq(49)
      expect(inst[0]).to eq({ args: ['${APACHE_LOCK_DIR}/accept.lock'], name: 'LockFile', ensure: :present, context: '' })
      expect(inst[5]).to eq({ args: ['5'], name: 'KeepAliveTimeout', ensure: :present, context: '' })
      expect(inst[30]).to eq({ args: ['150'], context: 'IfModule[1]', name: 'MaxClients', ensure: :present })
    end
  end

  context 'with simple file' do
    let(:tmptarget) { aug_fixture('simple') }
    let(:target) { tmptarget.path }

    it 'creates simple new entry' do
      apply!(Puppet::Type.type(:apache_directive).new(
               name: 'StartServers',
               args: '3',
               ensure: 'present',
               target: target,
               provider: 'augeas'
             ))

      # New entry gets added next to existing SetEnv entries
      augparse(target, 'Httpd.lns', '
        { "directive" = "SetEnv" { "arg" = "TEST" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "ignored" } }
        { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "test.com" } }
        { "directive" = "Example" }
        { "directive" = "StartServers" { "arg" = "3" } }
      ')
    end

    context 'when updating existing' do
      it 'updates existing' do
        apply!(Puppet::Type.type(:apache_directive).new(
                 name: 'Timeout',
                 args: '0',
                 ensure: 'present',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Httpd.lns') do |aug|
          expect(aug.get("directive[.='Timeout']/arg")).to eq('0')
        end
      end

      it 'clears args when only one arg' do
        apply!(Puppet::Type.type(:apache_directive).new(
                 name: 'SetEnv',
                 args: ['FQDN'],
                 args_params: 1,
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

      it 'fails with same name' do
        expect do
          apply!(
            Puppet::Type.type(:apache_directive).new(
              name: 'Listen',
              args: '80',
              target: target,
              provider: 'augeas'
            ),
            Puppet::Type.type(:apache_directive).new(
              name: 'Listen',
              args: '443',
              target: target,
              provider: 'augeas'
            )
          )
        end.to raise_error(Puppet::Resource::Catalog::DuplicateResourceError)
      end
    end

    context 'when creating with context' do
      it 'creating should create directive' do
        apply!(Puppet::Type.type(:apache_directive).new(
                 name: 'StartServers',
                 args_params: 0,
                 args: ['2'],
                 context: 'IfModule[1]',
                 ensure: 'present',
                 target: target,
                 provider: 'augeas'
               ))

        augparse(target, 'Httpd.lns', '
          { "directive" = "SetEnv" { "arg" = "TEST" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "ignored" } }
          { "directive" = "SetEnv" { "arg" = "FQDN" } { "arg" = "test.com" } }
          { "directive" = "Example" }
          { "IfModule" { "directive" = "StartServers" { "arg" = "2" } } }
        ')
        aug_open(target, 'Httpd.lns') do |aug|
          expect(aug.get("IfModule[1]/directive[.='StartServers']/arg")).to eq('2')
        end
      end
    end

    it 'deletes entries' do
      apply!(Puppet::Type.type(:apache_directive).new(
               name: 'Timeout',
               args: '0',
               ensure: 'absent',
               target: target,
               provider: 'augeas'
             ))

      aug_open(target, 'Httpd.lns') do |aug|
        expect(aug.match("directive[.='Timeout']").size).to eq(0)
      end
    end
  end

  context 'with full file' do
    let(:tmptarget) { aug_fixture('full') }
    let(:target) { tmptarget.path }

    context 'when using context' do
      it 'updating should update value' do
        apply!(Puppet::Type.type(:apache_directive).new(
                 name: 'StartServers',
                 args_params: 0,
                 args: 2,
                 context: "IfModule[arg='mpm_worker_module']",
                 ensure: 'present',
                 target: target,
                 provider: 'augeas'
               ))

        aug_open(target, 'Httpd.lns') do |aug|
          expect(aug.get("IfModule[arg='mpm_worker_module']/directive[.='StartServers']/arg")).to eq('2')
        end
      end

      it 'does not fail with different names and different context' do
        expect do
          apply!(
            Puppet::Type.type(:apache_directive).new(
              title: 'Listen80',
              name: 'Listen',
              args: '80',
              target: target,
              provider: 'augeas'
            ),
            Puppet::Type.type(:apache_directive).new(
              title: 'Listen443',
              name: 'Listen',
              args: '443',
              context: 'IfModule[arg="ssl_module"]',
              target: target,
              provider: 'augeas'
            )
          )
        end.not_to raise_error
      end
    end
  end

  context 'with broken file' do
    let(:tmptarget) { aug_fixture('broken') }
    let(:target) { tmptarget.path }

    if @logs.nil?
      @logs = []
      Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(@logs))
    end
    it 'fails to load' do
      txn = apply(Puppet::Type.type(:apache_directive).new(
                    name: 'SetEnv',
                    args: ['FQDN', 'test.com'],
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
