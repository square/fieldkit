FakeElement = require './helpers/fake_element'
FakeEvent = require './helpers/fake_event'
Caret = require './helpers/caret'
FormattedTextField = require '../lib/formatted_text_field'

class FakeFormatter
  format: (value) ->
    value

  parse: (text) ->
    text

describe 'FormattedTextField', ->
  element = null
  formattedTextField = null

  applyValueAndCaretDescription = (description) ->
    { caret, direction, value } = Caret.parseDescription description
    element.val value
    element.caret caret
    formattedTextField.selectionDirection = direction

  assertKeyPressTransform = (from, keys..., to) ->
    applyValueAndCaretDescription from

    for key in keys
      event = FakeEvent.withKey(key)
      event.type = 'keydown'
      formattedTextField.keyDown event
      if not event.isDefaultPrevented()
        event.type = 'keypress'
        if event.charCode
          formattedTextField.keyPress event
        if not event.isDefaultPrevented()
          event.type = 'keyup'
          formattedTextField.keyUp event

    description = Caret.printDescription
                    caret: element.caret()
                    direction: formattedTextField.selectionDirection
                    value: element.val()

    expect(description).toEqual(to)

  beforeEach ->
    element = new FakeElement()
    formattedTextField = new FormattedTextField(element)
    formattedTextField.formatter = new FakeFormatter()

  describe 'typing a character into an empty field', ->
    it 'allows the character to be inserted', ->
      assertKeyPressTransform '|', 'a', 'a|'

  describe 'typing a character into a full field', ->
    beforeEach ->
      formattedTextField.formatter.length = 2

    it 'does not allow the character to be inserted', ->
      assertKeyPressTransform '12|', '0', '12|'

    describe 'with part of the value selected', ->
      it 'replaces the selection with the typed character', ->
        assertKeyPressTransform '|1|2', '0', '0|2'

  describe 'typing a backspace', ->
    describe 'with a non-empty selection', ->
      it 'clears the selection', ->
        assertKeyPressTransform '12|34|5', 'backspace', '12|5'
        assertKeyPressTransform '12<34|5', 'backspace', '12|5'
        assertKeyPressTransform '12|34>5', 'backspace', '12|5'

        assertKeyPressTransform '12|3 4|5', 'alt+backspace', '12|5'
        assertKeyPressTransform '12<3 4|5', 'alt+backspace', '12|5'
        assertKeyPressTransform '12|3 4>5', 'alt+backspace', '12|5'

    describe 'with an empty selection', ->
      it 'works as expected', ->
        assertKeyPressTransform '|12', 'backspace', '|12'
        assertKeyPressTransform '1|2', 'backspace', '|2'

        assertKeyPressTransform '|12', 'alt+backspace', '|12'
        assertKeyPressTransform '12|', 'alt+backspace', '|'
        assertKeyPressTransform '12 34|', 'alt+backspace', '12 |'
        assertKeyPressTransform '12 |34', 'alt+backspace', '|34'

  describe 'typing forward delete', ->
    describe 'with a non-empty selection', ->
      it 'clears the selection', ->
        assertKeyPressTransform '12|34|5', 'delete', '12|5'
        assertKeyPressTransform '12<34|5', 'delete', '12|5'
        assertKeyPressTransform '12|34>5', 'delete', '12|5'

        assertKeyPressTransform '12|3 4|5', 'alt+delete', '12|5'
        assertKeyPressTransform '12<3 4|5', 'alt+delete', '12|5'
        assertKeyPressTransform '12|3 4>5', 'alt+delete', '12|5'

    describe 'with an empty selection', ->
      it 'works as expected', ->
        assertKeyPressTransform '12|', 'delete', '12|'
        assertKeyPressTransform '1|2', 'delete', '1|'

        assertKeyPressTransform '12|', 'alt+delete', '12|'
        assertKeyPressTransform '|12', 'alt+delete', '|'
        assertKeyPressTransform '|12 34', 'alt+delete', '| 34'
        assertKeyPressTransform '12| 34', 'alt+delete', '12|'

  describe 'typing a left arrow', ->
    it 'works as expected', ->
      assertKeyPressTransform '|4111', 'left', '|4111'
      assertKeyPressTransform '4|111', 'left', '|4111'
      assertKeyPressTransform '41|1|1', 'left', '41|11'

      assertKeyPressTransform '<41|11', 'shift+left', '<41|11'
      assertKeyPressTransform '4<1|11', 'shift+left', '<41|11'
      assertKeyPressTransform '|41>11', 'shift+left', '|4>111'
      assertKeyPressTransform '|4111 1>111', 'shift+left', '|4111 >1111'
      assertKeyPressTransform '41|1>1', 'shift+left', 'shift+left', '4<1|11'

      assertKeyPressTransform '41|11', 'alt+left', '|4111'
      assertKeyPressTransform '4111 11|11', 'alt+left', '4111 |1111'
      assertKeyPressTransform '4111 11|11', 'alt+left', 'alt+left', '|4111 1111'

      assertKeyPressTransform '41|11', 'shift+alt+left', '<41|11'
      assertKeyPressTransform '4111 11|11', 'shift+alt+left', '4111 <11|11'
      assertKeyPressTransform '4111 11|11', 'shift+alt+left', 'shift+alt+left', '<4111 11|11'

  describe 'typing a right arrow', ->
    it 'works as expected', ->
      assertKeyPressTransform '|4111', 'right', '4|111'
      assertKeyPressTransform '4111|', 'right', '4111|'
      assertKeyPressTransform '41|1|1', 'right', '411|1'

      assertKeyPressTransform '41|11>', 'shift+right', '41|11>'
      assertKeyPressTransform '<41|11', 'shift+right', '4<1|11'
      assertKeyPressTransform '|41>11', 'shift+right', '|411>1'
      assertKeyPressTransform '|4111> 1111', 'shift+right', '|4111 >1111'
      assertKeyPressTransform '41<1|1', 'shift+right', 'shift+right', '411|1>'

      assertKeyPressTransform '41|11', 'alt+right', '4111|'
      assertKeyPressTransform '41|11 1111', 'alt+right', '4111| 1111'
      assertKeyPressTransform '41|11 1111', 'alt+right', 'alt+right', '4111 1111|'

      assertKeyPressTransform '41|11', 'shift+alt+right', '41|11>'
      assertKeyPressTransform '41|11 1111', 'shift+alt+right', '41|11> 1111'
      assertKeyPressTransform '41|11 1111', 'shift+alt+right', 'shift+alt+right', '41|11 1111>'

  describe 'typing an up arrow', ->
    it 'works as expected', ->
      assertKeyPressTransform '4111|', 'up', '|4111'
      assertKeyPressTransform '411|1', 'up', '|4111'
      assertKeyPressTransform '41|1|1', 'up', '|4111'
      assertKeyPressTransform '41|1>1', 'up', '|4111'
      assertKeyPressTransform '41<1|1', 'up', '|4111'

      assertKeyPressTransform '41|11>', 'shift+up', '<41|11'
      assertKeyPressTransform '<41|11', 'shift+up', '<41|11'
      assertKeyPressTransform '|41>11', 'shift+up', '|4111'
      assertKeyPressTransform '|4111> 1111', 'shift+up', '|4111 1111'
      assertKeyPressTransform '41<1|1', 'shift+up', '<411|1'

      assertKeyPressTransform '41|11', 'alt+up', '|4111'
      assertKeyPressTransform '41|11 1111', 'alt+up', '|4111 1111'

      assertKeyPressTransform '41|11', 'shift+alt+up', '<41|11'
      assertKeyPressTransform '4111 11|11', 'shift+alt+up', '<4111 11|11'
      assertKeyPressTransform '4111 11|11', 'shift+alt+up', 'shift+alt+up', '<4111 11|11'

  describe 'typing a down arrow', ->
    it 'works as expected', ->
      assertKeyPressTransform '|4111', 'down', '4111|'
      assertKeyPressTransform '411|1', 'down', '4111|'
      assertKeyPressTransform '41|1|1', 'down', '4111|'
      assertKeyPressTransform '41|1>1', 'down', '4111|'
      assertKeyPressTransform '41<1|1', 'down', '4111|'

      assertKeyPressTransform '41|11>', 'shift+down', '41|11>'
      assertKeyPressTransform '<41|11', 'shift+down', '41|11>'
      assertKeyPressTransform '41<11|', 'shift+down', '4111|'
      assertKeyPressTransform '|4111> 1111', 'shift+down', '|4111 1111>'
      assertKeyPressTransform '41|1>1', 'shift+down', '41|11>'

      assertKeyPressTransform '41|11', 'alt+down', '4111|'
      assertKeyPressTransform '41|11 1111', 'alt+down', '4111 1111|'

      assertKeyPressTransform '41|11', 'shift+alt+down', '41|11>'
      assertKeyPressTransform '41|11 1111', 'shift+alt+down', '41|11 1111>'
      assertKeyPressTransform '4111| 1111', 'shift+alt+down', 'shift+alt+down', '4111| 1111>'

  describe 'selecting everything', ->
    ['ctrl', 'meta'].forEach (modifier) ->
      describe "with the #{modifier} key", ->
      it 'works without an existing selection', ->
        assertKeyPressTransform '123|4567', "#{modifier}+a", '|1234567|'

      it 'works with an undirected selection', ->
        assertKeyPressTransform '|123|4567', "#{modifier}+a", '|1234567|'

      it 'works with a right-directed selection and resets the direction', ->
        assertKeyPressTransform '|123>4567', "#{modifier}+a", '|1234567|'

      it 'works with a left-directed selection and resets the direction', ->
        assertKeyPressTransform '<123|4567', "#{modifier}+a", '|1234567|'