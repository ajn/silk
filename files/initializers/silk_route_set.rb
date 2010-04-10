module ActionDispatch
  module Routing
    class RouteSet #:nodoc:
      def draw(&block)
        clear! unless @disable_clear_and_finalize

        ::Silk::Routes.apply!(self, &block)

        finalize! unless @disable_clear_and_finalize

        nil
      end
    end
  end
end
