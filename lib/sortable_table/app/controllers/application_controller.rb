module SortableTable
  module App
    module Controllers
      module ApplicationController

        def self.included(base)
          base.class_eval do
            include InstanceMethods
            extend ClassMethods
          end
        end
        
        module ClassMethods

          def sortable_attributes(*args)
            mappings           = pop_hash_from_list(args)
            acceptable_columns = join_array_and_hash_values(args, mappings)
            define_sort_order(acceptable_columns, mappings)
          end
          
          def pop_hash_from_list(args)
            if args.last.is_a?(Hash)
              args.pop
            else
              {}
            end
          end
          
          def join_array_and_hash_values(array, hash)
            array.collect { |each| each.to_s } + 
              hash.keys.collect { |each| each.to_s }
          end
          
          def define_sort_order(acceptable_columns, mappings)
            define_method(:default_sort_column) do
              acceptable_columns.first
            end

            attr_accessor :current_sort_direction, :default_sort_direction

            define_method(:sort_order) do |*default| 
              default = default.first
              current_direction = calculate_current_sort_direction(params[:order], default)

              self.default_sort_direction = default_specified?(default) ? default[:default] : self.class::DEFAULT_SORT_DIRECTION
              
              column = params[:sort] || default_sort_column
              self.current_sort_direction = current_direction
              if params[:sort] && acceptable_columns.include?(column)
                column = mappings[column.to_sym] || column
                handle_compound_sorting(column, sql_sort_direction(current_direction))
              else
                "#{acceptable_columns.first} #{sql_sort_direction(current_direction)}"
              end
            end

            helper_method :sort_order, :default_sort_column, :current_sort_direction, :default_sort_direction
          end

        end
        
        module InstanceMethods
          const_set 'DEFAULT_SORT_DIRECTION', "descending"

          def default_specified?(default)
            default.is_a?(Hash) && default[:default]
          end

          def calculate_current_sort_direction(order, default)
            case
            when ! order.blank?                           then normalize_direction(order)
            when default_specified?(default) then normalize_direction(default[:default])
            else DEFAULT_SORT_DIRECTION
            end
          end

          def sql_sort_direction(direction)
            case direction
            when "ascending",  "asc" then "asc"
            when "descending", "desc" then "desc"
            end
          end

          def normalize_direction(direction)
            case direction
            when "ascending", "asc" then "ascending"
            when "descending", "desc" then "descending"
            else raise RuntimeError.new("Direction must be ascending, asc, descending, or desc")
            end
          end
          
          def handle_compound_sorting(column, direction)
            if column.is_a?(Array)
              column.collect { |each| "#{each} #{direction}" }.join(',')
            else
              "#{column} #{direction}"
            end
          end
        end

      end
    end
  end
end

