# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop identifies places where a case-insensitive string comparison
      # can better be implemented using `casecmp`.
      #
      # @example
      #   @bad
      #   'aBc'.downcase == 'abc'
      #   'abc'.upcase.eql? 'ABC'
      #   'abc' == 'ABC'.downcase
      #   'ABC'.eql? 'abc'.upcase
      #   'abc'.downcase == 'abc'.downcase
      #
      #   @good
      #   'aBc'.casecmp('ABC').zero?
      #   'abc'.casecmp('abc').zero?
      #   'abc'.casecmp('ABC'.downcase).zero?
      class Casecmp < Cop
        MSG = 'Use `casecmp` instead of `%s %s`.'.freeze
        CASE_METHODS = [:downcase, :upcase].freeze

        def_node_matcher :downcase_eq, <<-END
          (send $(send _ ${:downcase :upcase}) ${:== :eql? :!=} $_)
        END

        def_node_matcher :eq_downcase, <<-END
          (send _ ${:== :eql? :!=} $(send _ ${:downcase :upcase}))
        END

        def on_send(node)
          return if part_of_ignored_node?(node)

          downcase_eq(node) do |send_downcase, case_method, eq_method, other|
            *_, method = *other
            if CASE_METHODS.include?(method)
              range = node.loc.expression
              ignore_node(node)
            else
              range = node.loc.selector.join(send_downcase.loc.selector)
            end

            add_offense(node, range, format(MSG, case_method, eq_method))
            return
          end

          eq_downcase(node) do |eq_method, send_downcase, case_method|
            range = node.loc.selector.join(send_downcase.loc.selector)
            add_offense(node, range, format(MSG, eq_method, case_method))
          end
        end

        def autocorrect(node)
          downcase_eq(node) do
            receiver, method, arg = *node
            variable, = *receiver
            return correction(node, receiver, method, arg, variable)
          end

          eq_downcase(node) do
            arg, method, receiver = *node
            variable, = *receiver
            return correction(node, receiver, method, arg, variable)
          end
        end

        private

        def correction(node, _receiver, method, arg, variable)
          lambda do |corrector|
            corrector.insert_before(node.loc.expression, '!') if method == :!=

            # we want resulting call to be parenthesized
            # if arg already includes one or more sets of parens, don't add more
            # or if method call already used parens, again, don't add more
            replacement = if arg.send_type? || !parentheses?(arg)
                            "#{variable.source}.casecmp(#{arg.source}).zero?"
                          else
                            "#{variable.source}.casecmp#{arg.source}.zero?"
                          end

            corrector.replace(node.loc.expression, replacement)
          end
        end
      end
    end
  end
end
