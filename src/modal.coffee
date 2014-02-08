Ember.Widgets.ModalComponent =
Ember.Component.extend Ember.Widgets.StyleBindingsMixin,
  layoutName: 'modal'
  classNames: ['modal']
  classNameBindings: ['isShowing:in', 'hasCloseButton::has-no-close-button','fade']
  modalPaneBackdrop: '<div class="modal-backdrop"></div>'
  bodyElementSelector: '.modal-backdrop'

  enforceModality:  no
  backdrop:         yes
  isShowing:        no
  hasCloseButton:   yes
  fade:             yes
  headerText:       "Modal Header"
  confirmText:      "Confirm"
  cancelText:       "Cancel"
  closeText:        null
  content:          ""
  isValid: true

  confirm: Ember.K
  cancel: Ember.K
  close: Ember.K

  contentViewClass: Ember.View.extend
    template: Ember.Handlebars.compile("<p>{{content}}</p>")

  footerViewClass:  Ember.View.extend
    templateName: 'modal_footer'

  _contentViewClass: Ember.computed ->
    contentViewClass = @get 'contentViewClass'
    if typeof contentViewClass is 'string'
      Ember.get contentViewClass
    else contentViewClass
  .property 'contentViewClass'

  _footerViewClass: Ember.computed ->
    footerViewClass = @get 'footerViewClass'
    if typeof footerViewClass is 'string'
      Ember.get footerViewClass
    else footerViewClass
  .property 'footerViewClass'

  actions:
    # Important: we do not want to send cancel after modal is closed.
    # It turns out that this happens sometimes which leads to undesire
    # behaviors
    sendCancel: ->
      return unless @get('isShowing')
      # NOTE: we support callback for backward compatibility.
      cancel = @get 'cancel'
      if typeof(cancel) is 'function' then @cancel() else @sendAction 'cancel'
      @hide()

    sendConfirm: ->
      return unless @get('isShowing')
      # NOTE: we support callback for backward compatibility.
      confirm = @get 'confirm'
      if typeof(confirm) is 'function' then @confirm() else @sendAction 'confirm'
      @hide()

    sendClose: ->
      return unless @get('isShowing')
      # NOTE: we support callback for backward compatibility.
      close = @get 'close'
      if typeof(close) is 'function' then @close() else @sendAction 'close'
      @hide()

  didInsertElement: ->
    @_super()
    # See force reflow at http://stackoverflow.com/questions/9016307/
    # force-reflow-in-css-transitions-in-bootstrap
    @$()[0].offsetWidth if @get('fade')
    # append backdrop
    @_appendBackdrop() if @get('backdrop')
    # show modal in next run loop so that it will fade in instead of appearing
    # abruptly on the screen
    Ember.run.next this, -> @set 'isShowing', yes
    # bootstrap modal adds this class to the body when the modal opens to
    # transfer scroll behavior to the modal
    $(document.body).addClass('modal-open')
    @_setupDocumentHandlers()

  willDestroyElement: ->
    @_super()
    @_removeDocumentHandlers()

  click: (event) ->
    return if event.target isnt event.currentTarget
    @hide() unless @get('enforceModality')

  hide: ->
    @set 'isShowing', no
    # bootstrap modal removes this class from the body when the modal cloases
    # to transfer scroll behavior back to the app
    $(document.body).removeClass('modal-open')
    # fade out backdrop
    @_backdrop.removeClass('in')
    # remove backdrop and destroy modal only after transition is completed
    @$().one $.support.transition.end, =>
      @_backdrop.remove() if @_backdrop
      # We need to wrap this in a run-loop otherwise ember-testing will complain
      # about auto run being disabled when we are in testing mode.
      Ember.run this, @destroy

  _appendBackdrop: ->
    parentLayer = @$().parent()
    modalPaneBackdrop = @get 'modalPaneBackdrop'
    @_backdrop = jQuery(modalPaneBackdrop).addClass('fade') if @get('fade')
    @_backdrop.appendTo(parentLayer)
    # show backdrop in next run loop so that it can fade in
    Ember.run.next this, -> @_backdrop.addClass('in')

  _setupDocumentHandlers: ->
    @_super()
    unless @_hideHandler
      @_hideHandler = => @hide()
      $(document).on 'modal:hide', @_hideHandler

  _removeDocumentHandlers: ->
    @_super()
    $(document).off 'modal:hide', @_hideHandler
    @_hideHandler = null

Ember.Widgets.ModalComponent.reopenClass
  rootElement: '.ember-application'
  poppedModal: null

  hideAll: -> $(document).trigger('modal:hide')

  popup: (options = {}) ->
    @hideAll()
    rootElement = options.rootElement or @rootElement
    modal = this.create options
    modal.set 'container', modal.get('targetObject.container')
    modal.appendTo rootElement
    modal

Ember.Handlebars.helper('modal-component', Ember.Widgets.ModalComponent)
