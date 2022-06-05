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
        puts mouse_x
        puts mouse_y
        case @state
        when State::MAIN_SCREEN
            if id == Gosu::KB_ENTER or id == Gosu::KB_RETURN
                try_switch_to_viewer()
            end
        when State::VIEWER_SCREEN
            handle_viewer_button_down(id)
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
    def x_scale()
        return height.to_f / (@graph_end_x - @graph_start_x).to_f
    end
    def y_scale()
        return -height.to_f / (@graph_end_y - @graph_start_y).to_f
    end

    def cartesian2screen(x, y)
        # Converts cartesian coordinates in graph space to pixel coordinates in screen space.
        return [cartesian2screen_x(x), cartesian2screen_y(y)]
    end

    def cartesian2screen_x(x)
        x_off = -((@graph_end_x + @graph_start_x) / 2) * x_scale + height/2
        return x * x_scale + x_off
    end

    def cartesian2screen_y(y)
        y_off = -((@graph_end_y + @graph_start_y) / 2) * y_scale + height/2
        return y * y_scale + y_off
    end

    def initialize_viewer_screen()
        @state = State::VIEWER_SCREEN

        @translate_increment = 50  # Number of pixels in screen space
        @control_tips_texture = Gosu::Image.from_text('← ↑ → ↓: Move view', 20)

        @plot_values = generate_plot_values()
    end

    def generate_plot_values()
        values = []  # array of [x, y] values

        x = @graph_start_x
        while x < @graph_end_x
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

        # debug
        for p in values
            puts "(#{p[0]}, #{p[1]})"
        end
        return values
    end

    def draw_viewer_screen()
        draw_viewer(0, 0)
        # draw_graph_parameters()
        draw_controls_tips(610, 300)
    end

    def draw_viewer(left_x, top_y)
        size = height

        draw_viewer_background(left_x, top_y, size)
        draw_grid(left_x, top_y, size, 2.0)
        draw_axes(left_x, top_y, size)
        draw_graph(left_x, top_y, size)
    end

    def draw_viewer_background(left_x, top_y, size)
        Gosu.draw_rect(left_x, top_y, size, size, Gosu::Color::WHITE, ZOrder::BACKGROUND)
    end

    def draw_axes(left_x, top_y, size)
        mid_x, mid_y = *cartesian2screen(0, 0)

        Gosu.draw_line(
            0, mid_y, Gosu::Color::BLACK,
            size, mid_y, Gosu::Color::BLACK
        )

        if mid_x <= size  # to ensure that it stays in bounds
            Gosu.draw_line(
                mid_x, 0, Gosu::Color::BLACK,
                mid_x, size, Gosu::Color::BLACK
            )
        end
    end

    def draw_grid(left_x, top_y, size, gap)
        color = Gosu::Color.new(255, 220, 220, 220)

        x, y = *cartesian2screen(
            (@graph_start_x/gap).to_i * gap + left_x,
            (@graph_end_y/gap).to_i * gap + top_y  # end, to go top to bottom
        )

        while x < size
            Gosu.draw_line(
                x, 0, color,
                x, size, color
            )
            x += gap * x_scale.abs
        end

        while y < size
            Gosu.draw_line(
                0,    y, color,
                size, y, color
            )
            y += gap * y_scale.abs  # abs, because y_scale is usually negative
        end
    end

    def draw_graph(left_x, top_y, size)
        color = Gosu::Color::RED
        # width = 3

        for i in 0..(@plot_values.length-2)  # Iterate from the first element to the second last
            point1 = cartesian2screen(*@plot_values[i])
            point2 = cartesian2screen(*@plot_values[i+1])

            Gosu.draw_line(*point1, color, *point2, color)
        end
    end

    def translate_graph(x, y)
        # Translate the graph by a certain number of pixels in a direction.
        x_scale = height / (@graph_end_x - @graph_start_x)
        y_scale = height / (@graph_end_y - @graph_start_y)

        @graph_start_x += x / x_scale  # Dividing to transform into coordinate space
        @graph_end_x += x / x_scale
        @graph_start_y += y / y_scale
        @graph_end_y += y / y_scale

        @plot_values = generate_plot_values()
    end

    def translate_graph_right()
        translate_graph(@translate_increment, 0)
    end

    def translate_graph_left()
        translate_graph(-@translate_increment, 0)
    end

    def translate_graph_up()
        translate_graph(0, @translate_increment)
    end

    def translate_graph_down()
        translate_graph(0, -@translate_increment)
    end

    def handle_viewer_button_down(id)
        case id
        when Gosu::KB_RIGHT
            translate_graph_right()
        when Gosu::KB_LEFT
            translate_graph_left()
        when Gosu::KB_UP
            translate_graph_up()
        when Gosu::KB_DOWN
            translate_graph_down()
        end
    end

    def draw_controls_tips(left_x, top_y)
        @control_tips_texture.draw(left_x, top_y, ZOrder::TOP, 1, 1, Gosu::Color::BLACK)
    end
    #  /Viewer screen
end

window = GrapherWindow.new(800, 600)
window.show()