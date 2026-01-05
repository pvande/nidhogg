# @title A Guide to UI

# A Guide to UI

So, you've been building your game for a while now, and it's finally time for
you to tackle your game's UI elements. Whether it's a pause menu, a settings
screen, or a simple modal dialog, most games end up incorporating some sort of
UI control eventually.

You may have noticed that DragonRuby doesn't have any built-in UI controls for
you to leverage. While this is a deliberate design decision — and one that will
likely benefit you in the long-run — it can also be difficult to know where to
start when building your own controls. This guide will provide an exploration of
how you can build simple controls yourself, how you might structure that code,
and how Nidhogg can facilitate that work.

## Start at the Beginning

At its most primitive, a UI element (we'll use a button for our initial
discussion) can be thought of as somethign drawn to the screen that a user can
interact with. While the interactions may not be the same, it's not
fundamentally different than drawing a character to the screen.

A useful first step is to enumerate the kinds of interactions your component
will need. For a button, common interactions include **hovering** (e.g. with a
cursor), **focusing** (e.g. with a keyboard or controller), and **activating**
(e.g. pressing, tapping, or clicking). If we think about things in terms of
*which states* a button can be in, it could be `hovered`, `focused`,
`pressed`, or in its "default" state. If your buttons aren't always usable,
you might also consider a `disabled` state, which suggests that the "default"
state might be `enabled`.

Regardless of how we choose to implement our button component, we'll want to
represent whatever component state is relevant to our needs.

## My First Button

As an initial pass, let's write the simplest button we can think of. For our
purposes, we'll ignore the `focused` state and interaction, and direct our
attention to getting "hover" and "click" feeling good.

``` ruby
def tick(args)
  centered = args.grid.center.merge(anchor_x: 0.5, anchor_y: 0.5)
  rect = centered.merge(w: 200, h: 30, path: :solid)

  state = :enabled
  if args.inputs.mouse.inside_rect?(rect)
    state = args.inputs.mouse.down ? :active : :hover
  end

  args.outputs.sprites << rect.merge($button_colors[state])
  args.outputs.labels << rect.merge(text: "Button", vertical_alignment_enum: 0)
end

$button_colors = {
  enabled: { r: 200, g: 200, b: 200 },
  hover: { r: 200, g: 220, b: 200 },
  active: { r: 160, g: 180, b: 160 },
}
```

This isn't too bad — we've got a button that's centered on the screen, and its
properties change when hovered and when clicked. It's also not hard to see how
this might be extended to support other presentations — if your button design
wants to be a good deal fancier, you might swap the `solid` background for a
`sprite` with a state-specific image, for example.

That's not to say that this example doesn't have a shortcomings.
* The `active` state is only triggered for a single tick.
* It would be difficult to build transitions between states.
* There is no "one thing" that is "a button".

We'll punt on that last point for now, and focus on the first two.

## States of Being

The reason we fall out of the `active` state so quickly is the same reason we
can't easily build state transitions: we're not really *tracking* the state of
the button from frame to frame. Let's go ahead and make that change, and
implement a simple rotational animation on hover.

``` ruby
def tick(args)
  if Kernel.tick_count.zero?
    centered = args.grid.center.merge(anchor_x: 0.5, anchor_y: 0.5)
    centered.merge!(angle_anchor_x: 0.5, angle_anchor_y: 0.5)
    rect = centered.merge(w: 200, h: 30, path: :solid, angle: 0)

    args.state.button = { hover: nil, press: nil, target: 0, rect: rect }
  end

  state = args.state.button
  rect = state.rect

  if state.hover != args.inputs.mouse.inside_rect?(rect)
    state.hover = args.inputs.mouse.inside_rect?(rect)
    state.target = state.hover ? 6 : 0
  end

  state.press = nil if args.inputs.mouse.up
  state.press ||= args.inputs.mouse.down if state.hover

  state.background = :enabled
  state.background = :hover if state.hover
  state.background = :active if state.press

  state.rect.angle += (state.target - state.rect.angle).fdiv(4)

  args.outputs.sprites << rect.merge($button_colors[state.background])
  args.outputs.labels << rect.merge(text: "Button", vertical_alignment_enum: 0)
end

$button_colors = {
  enabled: { r: 200, g: 200, b: 200 },
  hover: { r: 200, g: 220, b: 200 },
  active: { r: 160, g: 180, b: 160 },
}
```

This is looking better, and we're tracking the button's state from frame to
frame now, which means we can start to build transitions between states (whether
that's setting up a jaunty rotation on hover, or a crossfade between sprites, or
whatever else you can imagine). It's also a very *direct* way to implement a
button — every tick, we check on what the mouse is doing, and we update the
button accordingly, in the same way we would update a game sprite in response to
controller input.

If you only ever need a simple UI, this could be completely reasonable. You'll
have a region in your tick method (or a method called by your tick method) for
configuring and updating your UI elements, and it's just another thing you do.

It's also fair to note, though, that there's a lot of code here, just to render
a single button. If you're building a game with a lot of UI, you'll find
yourself repeating a lot of this logic as well (though well abstracted functions
can help).

``` ruby
def init(args)
  centered = args.grid.center.merge(anchor_x: 0.5, anchor_y: 0.5)

  args.state.background_color = { r: 200, g: 255, b: 200 }
  args.state.button_one = init_button("Red", centered.shift_rect(0, 40)) do
    args.state.background_color = { r: 255, g: 200, b: 200 }
  end
  args.state.button_two = init_button("Green", centered) do
    args.state.background_color = { r: 200, g: 255, b: 200 }
  end
  args.state.button_three = init_button("Blue", centered.shift_rect(0, -40)) do
    args.state.background_color = { r: 200, g: 200, b: 255 }
  end
end

def tick(args)
  init(args) if Kernel.tick_count.zero?

  args.outputs.background_color = args.state.background_color

  tick_button(args, args.state.button_one)
  tick_button(args, args.state.button_two)
  tick_button(args, args.state.button_three)
end

def init_button(text, position, &click)
  position.merge(
    w: 200,
    h: 30,
    path: :solid,
    angle_anchor_x: 0.5,
    angle_anchor_y: 0.5,
    background_color: $button_colors.enabled,
    on_click: click,

    text: text,
    vertical_alignment_enum: 0,
    text_color: { r: 0, g: 0, b: 0 },

    mouse_over: false,
    mouse_down: nil,
    since: Kernel.tick_count,
    target_angle: 0,
    angle: 0
  )
end

def tick_button(args, button)
  if button.mouse_over != args.inputs.mouse.inside_rect?(button)
    button.mouse_over = args.inputs.mouse.inside_rect?(button)
    button.target_angle = button.mouse_over ? rand(30) - 15 : 0
    button.since = Kernel.tick_count
  end

  button.mouse_down = nil if args.inputs.mouse.up
  if button.mouse_over
    button.mouse_down = args.inputs.mouse.down
    button.on_click&.call if args.inputs.mouse.up
  end

  if button.mouse_down
    button.background_color = $button_colors.active
  elsif button.mouse_over
    button.background_color = $button_colors.hover
  else
    button.background_color = $button_colors.enabled
  end

  button.angle += (button.target_angle - button.angle).fdiv(4)

  args.outputs.sprites << button.merge(button.background_color)
  args.outputs.labels << button.merge(button.text_color)
end

$button_colors = {
  enabled: { r: 200, g: 200, b: 200 },
  hover: { r: 200, g: 220, b: 200 },
  active: { r: 160, g: 180, b: 160 },
}
```

Here, we've been able to pull out game initialization, button initialization and
button tick logic into separate methods, which allows us to add new UI buttons
without adding substantially more code. Refactored this way, we've now isolated
the logic for our UI elements, though we *can* go further…

## Class is in Session

Object-oriented programming is a powerful tool for managing complexity, and Ruby
is a famously object-oriented language. Practically speaking, an "object" is the
name given to a bundle of state data and behavior that are closely related. Most
object-oriented languages describe "classes" of objects, which all share common
data and behaviors — an object, then, is an *instance* of a class.

``` ruby
def init(args)
  centered = args.grid.center.merge(anchor_x: 0.5, anchor_y: 0.5)

  args.state.background_color = { r: 200, g: 255, b: 200 }
  args.state.button_one = Button.new("Red", centered.shift_rect(0, 40)) do
    args.state.background_color = { r: 255, g: 200, b: 200 }
  end
  args.state.button_two = Button.new("Green", centered) do
    args.state.background_color = { r: 200, g: 255, b: 200 }
  end
  args.state.button_three = Button.new("Blue", centered.shift_rect(0, -40)) do
    args.state.background_color = { r: 200, g: 200, b: 255 }
  end
end

def tick(args)
  init(args) if Kernel.tick_count.zero?

  args.outputs.background_color = args.state.background_color

  args.state.button_one.tick(args)
  args.state.button_two.tick(args)
  args.state.button_three.tick(args)

  args.state.button_one.render(args)
  args.state.button_two.render(args)
  args.state.button_three.render(args)
end

class Button
  COLORS = {
    enabled: { r: 200, g: 200, b: 200 },
    hover: { r: 200, g: 220, b: 200 },
    active: { r: 160, g: 180, b: 160 },
  }

  def initialize(text, position, &click)
    @rect = position.merge(w: 200, h: 30)
    @text = text
    @on_click = click
    @background = COLORS.enabled
    @foreground = { r: 0, g: 0, b: 0 }

    @state = {
      mouse_over: false,
      mouse_down: nil,
      since: Kernel.tick_count,
      target_angle: 0,
      angle: 0
    }
  end

  def tick(args)
    if @state.mouse_over != args.inputs.mouse.inside_rect?(@rect)
      @state.mouse_over = args.inputs.mouse.inside_rect?(@rect)
      @state.target_angle = @state.mouse_over ? rand(30) - 15 : 0
      @state.since = Kernel.tick_count
    end

    @state.mouse_down = nil if args.inputs.mouse.up
    if @state.mouse_over
      @state.mouse_down = args.inputs.mouse.down
      @on_click.call if args.inputs.mouse.up
    end

    if @state.mouse_down
      @state.background = COLORS.active
    elsif @state.mouse_over
      @state.background = COLORS.hover
    else
      @state.background = COLORS.enabled
    end

    @state.angle += (@state.target_angle - @state.angle).fdiv(4)
  end

  def render(args)
    args.outputs.sprites << @rect.merge(@background).merge!(
      path: :solid,
      angle: @state.angle,
      angle_anchor_x: 0.5,
      angle_anchor_y: 0.5
    )
    args.outputs.labels << @rect.merge(@foreground).merge(
      text: @text,
      vertical_alignment_enum: 0
    )
  end
end
```
