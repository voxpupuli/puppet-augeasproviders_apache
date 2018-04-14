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

  newparam(:name) do
    desc 'The directive name'
    isnamevar
  end

  newparam(:context) do
    desc 'The path where the directive is located. Expressed as an Augeas path expression.'
    isnamevar
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
    isnamevar
  end

  def self.title_patterns
    [
      [
        /^(\S+)\s+from\s+(\S+)\s+in\s+(.*)$/,
        [
          [ :name ],
          [ :context ],
          [ :target ],
        ]
      ],
      [
        /^(\S+)\s+from\s+(\S+)$/,
        [
          [ :name ],
          [ :context ],
        ]
      ],
      [
        /^(\S+)\s+in\s+(.*)$/,
        [
          [ :name ],
          [ :target ],
        ]
      ],
      [
        /(.*)/,
        [
          [ :name ],
        ]
      ]
    ]
  end
end
