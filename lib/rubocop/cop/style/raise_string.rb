# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop checks for raise with a string literal instead of a
      # class or exception object.
      class RaiseString < Cop
        MSG = 'Raise an exception class or object, not a string.'.freeze

        def on_send(node)
          _receiver, method, *args = *node
          return unless [:raise, :fail].member?(method)
          return unless args[0].str_type?
          add_offense(args[0], :selector)
        end
      end
    end
  end
end
