# Manages Apache directives
#
# Copyright (c) 2013 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:apache_directive) do
  @doc = 'Manages Apache directives'

  ensurable do
    defaultvalues
    block if block_given?

    newvalue(:positioned) do
      current = self.retrieve
      if current == :absent
        provider.create
      elsif !provider.in_position?
        provider.destroy
        provider.create
      end
    end

    def insync?(is)
      return true if should == :positioned and is == :present and provider.in_position?
      super
    end
  end

  newparam(:namevar) do
    desc 'The directive name var as utilized for resource control'
    isnamevar
  end

  newparam(:name) do
    desc 'The directive name'
  end

  newparam(:context) do
    desc 'The path where the directive is located. Expressed as an Augeas path expression.'
    defaultto ''
  end

  newproperty(:args, :array_matching => :all) do
    desc 'An array of directive arguments'
  end

  newparam(:args_params) do
    desc 'How many arguments are to be used as params'
    defaultto 0

    validate do |value|
      raise "Wrong args_params value '#{value}'" unless value.to_i >= 0
    end
  end

  newparam(:target) do
    desc 'The config file to use'
  end

  def self.title_patterns
    identity = lambda { |x| x }
    [
      [
        /^((\S+)\s+of\s+(.+))$/,
        [
          [ :namevar, identity ],
          [ :name, identity ],
          [ :context, identity ],
        ]
      ],
      [
        /^((\S+)\s+of\s+(.+)\s+in\s+(.*))$/,
        [
          [ :namevar, identity ],
          [ :name, identity ],
          [ :context, identity ],
          [ :target, identity ],
        ]
      ],
      [
        /(.*)/,
        [
          [ :namevar, identity ],
          [ :name, identity ],
        ]
      ]
    ]
  end

end
