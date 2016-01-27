# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # This cop checks for unintentional potentially-truncating
      # integer divisions.
      #
      # @example
      #
      #  x / 100
      class IntegerTruncation < Cop
        MSG = 'Division may result in truncation - divide by a float ' \
              'constant or make integer division explicit with .to_i.'.freeze

        def on_send(node)
          receiver, method, args = *node
          return unless :'/' == method
          return unless args.literal? && :float != args.type
          return if receiver.send_type? && :to_f == extract_method(receiver)
          add_offense(node, :selector)
        end

        private

        def extract_method(node)
          _receiver, method_name, *_args = *node
          method_name
        end
      end
    end
  end
end
