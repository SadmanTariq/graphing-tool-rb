require 'gosu'
require './ui'


module State
    MAIN_SCREEN, VIEWER_SCREEN = *0..1
end

class GrapherWindow < Gosu::Window
    def initialize(window_width, window_height)
        super(window_width, window_height)
        self.caption = "Function Visualizer"

        @background_color = Gosu::Color::GRAY

        #  Default bound bounds of the graph
        @graph_start_x = -10.0
        @graph_end_x = 10.0
        @graph_start_y = -10.0
        @graph_end_y = 10.0

        #  Number of steps
        @graph_resolution = 100

        initialize_main_screen()
    end

    def needs_cursor?; true; end

    def update()

    end

    def draw()
        draw_background(@background_color)
        case @state
        when State::MAIN_SCREEN
            draw_main_screen()
        when State::VIEWER_SCREEN
            draw_viewer_screen()
        end
    end

    def button_down(id)
        case @state
        when State::MAIN_SCREEN
            if id == Gosu::KB_ENTER or id == Gosu::KB_RETURN
                try_switch_to_viewer()
            end
        end
    end

    def draw_background(color)
        Gosu.draw_rect(0, 0, width, height, color, ZOrder::BACKGROUND)
    end

    #  Main screen
    def initialize_main_screen()
        @state = State::MAIN_SCREEN
        self.text_input = Gosu::TextInput.new()

        @fx_texture = Gosu::Image.from_text('f(x) = ', 15)
        @text_box = Ui::TextBox.new(
            50 + @fx_texture.width,
            height / 2,
            600,
            Gosu::Color::WHITE,
            Gosu::Font.new(15, { name: "Consolas" }),
            self.text_input, 10,
            'Enter a function of x then press Enter...'
        )

        #  True if there is an error in the input function.
        @error = false
    end

    def draw_main_screen()
        top_y = @text_box.top_y
        left_x = 50

        @fx_texture.draw(
            left_x, top_y + @text_box.padding, ZOrder::MIDDLE,
            1, 1, Gosu::Color::BLACK
        )
        Ui.draw_text_box(@text_box)
    end
    #  /Main screen

    def get_fn_lambda()
        fn = nil

        if @text_box.text_input.text != ''
            begin
                eval("fn = lambda { |x| #{@text_box.text_input.text}}")
            rescue Exception => error
                puts(error.message)
                return nil
            end
        end

        return fn
    end
    def try_switch_to_viewer()
        if function_valid?(get_fn_lambda())
            @input_function = get_fn_lambda()
            @error = false
            self.text_input = nil

            initialize_viewer_screen()
        else
            @error = true
        end
    end

    def function_valid_at?(fn, x)
        #  Tests the function at a specific x-coordinate
        begin
            output_type = fn.call(x).class
            if output_type == Integer or output_type == Float
                return true
            else
                return false
            end
        rescue
            return false
        end
    end

    def function_valid?(fn)
        #  A function is considered valid if it is valid at
        #  at least one point.
        x = @graph_start_x
        while x <= @graph_end_x
            if function_valid_at?(fn, x)
                return true
            end
            x += (@graph_end_x - @graph_start_x) / @graph_resolution
        end

        return false
    end

    #  Viewer screen
    def initialize_viewer_screen()
        @state = State::VIEWER_SCREEN

        @plot_values = generate_plot_values()
    end

    def generate_plot_values()
        values = []  # array of [x, y] values

        x = @graph_start_x
        while x < @graph_end_y
            if function_valid_at?(@input_function, x)
                values << [x, @input_function.call(x)]
                x += (@graph_end_x - @graph_start_x) / @graph_resolution
            end
        end

        #  Include rightmost value
        if function_valid_at?(@input_function, x)
            x = @graph_end_x
            values << [x, @input_function.call(x)]
        end

        puts values
        return values
    end

    def draw_viewer_screen()
        draw_viewer(0, 0)
        # draw_graph_parameters()
        # draw_controls_tips()
    end

    def draw_viewer(left_x, top_y)
        size = height

        #  Amount to be multiplied
        x_scale = size / (@graph_end_x - @graph_start_x)
        y_scale = -size / (@graph_end_y - @graph_start_y)

        #  Amount of units to be shifted
        x_offset = ((@graph_end_x + @graph_start_x)/2) * x_scale + size/2
        y_offset = ((@graph_end_y + @graph_start_y)/2) * y_scale + size/2

        draw_viewer_background(left_x, top_y, size)
        draw_grid(left_x, top_y, x_offset, y_offset, x_scale, y_scale, size, 2.0)
        draw_axes(left_x, top_y, x_offset, y_offset, size)
        draw_graph(left_x, top_y, x_offset, y_offset, x_scale, y_scale, size)
    end

    def draw_viewer_background(left_x, top_y, size)
        Gosu.draw_rect(left_x, top_y, size, size, Gosu::Color::WHITE, ZOrder::BACKGROUND)
    end

    def draw_axes(left_x, top_y, x_offset, y_offset, size)
        mid_x = left_x + x_offset
        mid_y = top_y + y_offset

        Gosu.draw_line(
            0, mid_y, Gosu::Color::BLACK,
            size, mid_y, Gosu::Color::BLACK
        )
        Gosu.draw_line(
            mid_x, 0, Gosu::Color::BLACK,
            mid_x, size, Gosu::Color::BLACK
        )
    end

    def draw_grid(left_x, top_y, x_offset, y_offset, x_scale, y_scale, size, gap)
        # TODO: add offsets to grid
        color = Gosu::Color.new(255, 220, 220, 220)
        gap_x = (gap * x_scale).abs
        gap_y = (gap * y_scale).abs  # abs because y_scale is usually negative

        for x in 0..(size / gap_x)
            Gosu.draw_line(
                x * gap_x, 0, color,
                x * gap_x, size, color
            )
        end
        for y in 0..(size / gap_y)
            Gosu.draw_line(
                0, y * gap_y, color,
                size, y * gap_y, color
            )
        end
    end

    def draw_graph(left_x, top_y, x_offset, y_offset, x_scale, y_scale, size)
        color = Gosu::Color::RED
        width = 3

        for i in 0..(@plot_values.length-2)  # Iterate from the first element to the second last
            point1 = [
                @plot_values[i][0] * x_scale + x_offset,
                @plot_values[i][1] * y_scale + y_offset
            ]

            point2 = [
                @plot_values[i+1][0] * x_scale + x_offset,
                @plot_values[i+1][1] * y_scale + y_offset
            ]

            Gosu.draw_line(*point1, color, *point2, color)
        end
    end
end

window = GrapherWindow.new(800, 600)
window.show()