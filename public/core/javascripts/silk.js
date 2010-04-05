/*
  --------------------------------------------------------------------------
  Silk Javascript Library - Requires jQuery
  --------------------------------------------------------------------------
*/


/* MAIN */

silk = function() {
  version: "0.0.8";
};
silk.prototype = {
  
  init: function() {
    this.initialChecks();
    this.user = new silk.user();
    this.flash = new silk.flash().init().process();
    if (_silk_data.user) this.initUser();
    return this;
  },
  
  initUser: function() {
    this.processApps();
    this.page = $.extend(new silk.page(), _silk_data.page);
    this.page.init();
    this.admin_menu = new silk.admin_menu().init();
    return this;
  },
  
  // Called externally once the page has fully finished loading
  executeActions: function() {
    $(_silk_data.actions).each(function(){ eval(String(this));  });
  },
  
  initialChecks: function() {
    if (typeof(_silk_data) == "undefined") alert('Silk Error: The _silk_data variable is not present. Please ensure you include the silk_headers helper in your layout/page.');
    return this;
  },
  
  processApps: function() {
    this.apps = {};
    var obj = this;
    $.each(_silk_data.quick_access_apps, function() {
      obj.apps[this.app_name] = new silk.app(this);
    });
  },
  
},


/* Page */

silk.page = function() {
  this.highlight_editable_elements = false;
  this.editableElements = $('div.silk-editable-content');
};
silk.page.prototype = {
  
  init: function() {
    this.setupEditableContent();
    this.widget = new silk.dialog.widget();
    this.meta_tags = new silk.page.meta_tags();
    this.meta_tags.init();
    this.editPageIfNoContent();
    return this;
  },
  
  // Save time for the user by opening the Edit Page dialog if there is no title or content
  editPageIfNoContent: function() {
    if (this.id && !this.title && !this.body) this.edit();
    return this;
  },
  
  // The content dialog is shared between page and editable_content. This sets up the shared parameters.
  contentDialog: function() {
    if (this.content_dialog) return this.content_dialog;
    var dialog_options = { width: 920, height: 580, buttons: {
      'Save and close': function(){ $('#silk-dialog-form').submit(); },
      'Cancel': function(){ $(this).dialog('close'); },
    }};
    this.content_dialog = new silk.dialog('content', dialog_options);
    return this.content_dialog.init();
  },
  
  // For now, if the page came from the DB we assume it is editable. In the future check for permissions.
  isEditable: function() {
    if (this.id) return true;
  },
  
  edit: function() {
    this.contentDialog().title('Edit Page').body(this.form()).open();
    $("#silk-edit-content-textarea").val(this.body);
    $('#page-tabs').tabs();
    if (this.content != '' && this.title != null) $('#silk-edit-content-textarea').focus();
  },
  
  destroy: function() {
    this.widget.confirm('delete_page', 'Confirmation',
      '<p>Are you sure you want to <strong>permanently</strong> delete this page?</p> <p class="silk-dialog-page-path">' + this.path + '</p>',
       { 'Delete Page': function(){ $('#silk-dialog-form-delete_page').submit(); },
         'Cancel': function(){ $(this).dialog('close'); }, },
       '/silk/pages/' + this.id, 'delete');
  },
  
  numEditableContentAreas: function() {
    return this.editableElements.size();
  },
  
  // This method goes through the div elements which are editable and attaches the objects we created to them.
  // It also sets up the mouseover/out functionality which isn't very exciting at the moment but will do more in the future.
  setupEditableContent: function() {
    this.editableElements.each(function(){
      var id = $(this).attr('id').replace('silk-ec-area-id-','');
      var obj = _silk_data.editable_content[id];

      $(this).data('obj', obj).dblclick(function(){ $(this).editContents(); });
      $(this).data('originalBackgroundColor', $(this).css('backgroundColor'));
      
      $(this).mouseover(function(){ if (!Silk.page.highlight_editable_elements) obj.highlight(); });
      $(this).mouseout( function(){ if (!Silk.page.highlight_editable_elements) obj.unHighlight(); });
    });
    return this;
  },

  toggleHighlightEditableContent: function() {
    this.highlight_editable_elements = this.highlight_editable_elements ? false : true;
    this.editableElements.each(function(){ $(this).data('obj').toggleHighlight(); });
    return this; 
  },

  form: function() {
    return '<form id="silk-dialog-form" method="post" action="/silk/pages/' + this.id + '"><div id="silk-dialog-header">' +
         '<div id="silk-dialog-page-title"><input type="text" name="page[title]" value="' + (this.title || 'New Page Title') + '" tabindex="1"/></div>' +
         '<div id="silk-dialog-content-type-selector"></div>' +
      '</div><input type="hidden" name="_method" value="put"/><input type="hidden" name="authenticity_token" value="' + _silk_data.authenticity_token + '"/>' +
      
        '<div id="page-tabs">' +
          '<ul><li><a href="#page-tab-contents">Content</a></li><li><a href="#page-tab-properties">Properties</a></li><li><a href="#page-tab-meta">Meta Tags</a></li>' +
          '<div id="page-tab-contents"><textarea name="page[content_attributes][body]" id="silk-edit-content-textarea" tabindex="2"></textarea></div>' +
          '<div id="page-tab-properties">' + this.formTabProperties() + '</div>' +
          '<div id="page-tab-meta">' + this.meta_tags.render() + '</div>' +
        '</div>' +
        
      '</form>';
  },
  
  formTabProperties: function() {
    var obj = this;
    var output = '<div class="silk-tab-panel silk-tab-panel-padded">' +
      '<fieldset><label for="silk-page-content-type">Content Type</label>' +
        this.widget.contentTypeSelector(this, 'page[content_attributes][content_type]') +
      '<label for="silk-page-layout">Layout</label>' +
      '<select id="silk-page-layout" name="page[layout]">';
        $.each(_silk_data.available_layouts, function() {
          output += '<option value="' + this.layout + '" ' + (obj.layout == this.layout ? 'selected' : '') + '>' + this.label + '</option>';
        });
      output += '</select>' +
    '</fieldset></div>';
    return output;
  },
  
  // When an authenticated user visits a new page createNewPagePrompt() is automatically added to the list of actions to execute.
  // It pops up a dialog asking the user if they really want to create a new page. If so the Rails create action is called.
  createNewPagePrompt: function(path) {
    
    this.widget.confirm('create-new-page', 'Page Not Found',
      '<p>Would you like to create a new page at:</p> <p class="silk-dialog-page-path">' + path + '</p></div>',
       { 'Create Page': function(){ $('#silk-dialog-form-create-new-page').submit(); },
         'Cancel': function(){ $(this).dialog('close'); }, },
       '/silk/pages', 'post', '<input type="hidden" name="page[path]" value="' + path + '"/>');
  },
  
};


/* Page: Metatags */

silk.page.meta_tags = function() {
  this.static_types = ['keywords','description'];
};
silk.page.meta_tags.prototype = {
  
  init: function() {
    this.data = _silk_data.page && _silk_data.page.meta_tags ? _silk_data.page.meta_tags : [];
    return this;
  },
  
  render: function() {
    var output = '<div class="silk-tab-panel silk-tab-panel-padded">';
    output += '<p>Meta tags are used by some search engines to help categorise and rank this page. Is is not essential to add them to every page, but advisable if search engine optimization is important to you.</p><br/>';
    output += this.renderStatic() + this.renderCustom();
    output += '</div>';
    return output;
  },
  
  renderStatic: function() {
    var obj = this;
    var output = $.map(this.static_types, function(tag_type) {
      var data = $.grep(obj.data, function(x){ return x.name == tag_type })[0] || {name: tag_type}
      var tag = $.extend(data, new silk.page.meta_tag());
      return tag.renderStatic();
    });
    return output.join('');
  },
   
  renderCustom: function() {
    var output = '<div class="silk-meta-tag-section"><h4>Custom</h4><div class="silk-meta-tag-values"><div id="silk-meta-tags-custom">';
    output += $.map(this.data, function(data) {
      if (data.name == 'keywords' || data.name == 'description') return '';
      var tag = $.extend(data, new silk.page.meta_tag());
      return tag.renderCustom();
    }).join('');
    output += '</div>' + this.addNewButton() + '</div></div>';
    return output;
  },

  addNewButton: function() {
    return '<div class="silk-meta-tag-field" style="margin: 5px 0 0 0">' +
    '<a href="#" onclick="Silk.page.meta_tags.add(); return false;"><span class="silk-icon-add" /> Add custom tag</a>' +
    '</div>';
  },

  add: function() {
    var tag = new silk.page.meta_tag();
    $('#silk-meta-tags-custom').append(tag.renderCustom());
    return this;
  },
 
};


/* Page: Metatag */

silk.page.meta_tag = function() {
  this.static_types = {
    keywords:    {label: 'Keywords', explain: 'What is this page about? Isolate a few carefully chosen keywords and separate by commas.'},
    description: {label: 'Description', explain: 'Describe this page in one or two sentances. Some search engines will use this as the page summary.'},
  };
};
silk.page.meta_tag.prototype = {

  info: function() {
    return this.static_types[this.name];
  },
  
  renderStatic: function() {
    return '<div class="silk-meta-tag-section"><h4>' + this.info().label + '</h4>' +
      '<div class="silk-meta-tag-values"><input type="hidden" name="page[meta_tags][][name]" value="' + this.name + '" />' +
      '<input type="text" name="page[meta_tags][][content]" value="' + (this.content || '') + '" class="silk-static-value" onkeydown="return silk_prevent_quotes()" />' +
      '<p>' + this.info().explain + '</p></div></div>';
  },
  
  renderCustom: function() {
    return '<div class="silk-meta-tag-custom-field"><div class="silk-icon-delete" title="Double click to delete" onclick="$(this).parent().fadeOut().remove()" /> ' +
      '<input type="text" name="page[meta_tags][][name]" value="' + (this.name || '') + '" class="silk-custom-type" />' +
      '<input type="text" name="page[meta_tags][][content]" value="' + (this.content || '') + '" class="silk-custom-value" onkeydown="return silk_prevent_quotes()" />' +
      '</div>';
  },

};


/* Editable Content */

silk.editable_content = function() {
  this.widget = new silk.dialog.widget();
};
silk.editable_content.prototype = {
  
  element: function() {
    return $('#silk-ec-area-id-' + this.id);
  },
  
  // Note: The only difference between a snippet and regular content element is the nil path
  isSnippet: function() {
    if (this.path == null) return true;
  },
  
  edit: function() {
    var title = 'Edit &quot;' + this.name + '&quot; content';
    Silk.page.contentDialog().title(title).body(this.form()).open();
    $("#silk-edit-content-textarea").val(this.body);
    $('#content-tabs').tabs();
    this.showInfoLine();
  },

  highlightColor: function() {
    return this.isSnippet() ? '#A7FDB6' : '#FCFFA7';
  },

  highlight: function() {
    this.element().css('backgroundColor', this.highlightColor());
    return this;
  },
  
  unHighlight: function() {
    this.element().css('backgroundColor', this.element().data('originalBackgroundColor'));
    return this;
  },
  
  toggleHighlight: function() {
    if (Silk.page.highlight_editable_elements) {
      this.makeInvisibleAreasVisible().highlight();
    } else {
      this.restoreInvisibleAreas().unHighlight();
    }
    return this;
  },
  
  makeInvisibleAreasVisible: function() {
    if ($(this.element()).html() == '') $(this.element()).html('<div class="silk-editable-content-empty">Double click to add content to <strong>' + this.name + '</strong></div>');
    return this;
  },
  
  restoreInvisibleAreas: function() {
    if (this.element().find('div.silk-editable-content-empty').length) this.element().html('');
    return this;
  },

  form: function() {
    return '<form id="silk-dialog-form" method="post" action="/silk/content/' + this.id + '">' +
      '<div id="silk-dialog-header"><div id="silk-dialog-info-line"></div></div>' +
      '<input type="hidden" name="_method" value="put"/><input type="hidden" name="authenticity_token" value="' + _silk_data.authenticity_token + '"/>' +
      
        '<div id="content-tabs">' +
          '<ul><li><a href="#content-tab-contents">Content</a></li><li><a href="#content-tab-properties">Properties</a></li>' +
          '<div id="content-tab-contents"><textarea name="content[body]" id="silk-edit-content-textarea" tabindex="2"></textarea></div>' +
          '<div id="content-tab-properties">' + this.formTabProperties() + '</div>' +
        '</div>' +
      
      '</form>';
  },

  // Pretty much duplicated from page - lets refactor this
  formTabProperties: function() {
    var obj = this;
    var output = '<div class="silk-tab-panel silk-tab-panel-padded">' +
      '<fieldset><label for="silk-page-content-type">Content Type</label>' +
        this.widget.contentTypeSelector(this, 'content[content_type]') +
       '</fieldset></div>';
    return output;
  },

  showInfoLine: function() {
    if (this.isSnippet()) {
      $('#silk-dialog-info-line').hide().html('<div class="ui-icon ui-icon-info"></div> Caution: You are about to change content which may appear on several pages.').fadeIn();
    } else {
      $('#silk-dialog-info-line').html('');
    }
    return this;
  },
  
};


/* Users */

silk.user = function() {};
silk.user.prototype = {
  
  login: function() {
    var buttons = {
      'Login': function(){ $('#silk-dialog-user-login').submit(); },
      'Cancel': function(){ $(this).dialog('close'); },
    };
    var dialog_options = { width: 600, height: 290, buttons: buttons};
    var dialog = new silk.dialog('login', dialog_options).init();
    var body = '<form id="silk-dialog-user-login" method="post" action="/silk/sessions"><div class="silk-dialog-padding">' + this.formLogin() + '</div>' +
      '<input type="hidden" name="_method" value="post"/><input type="hidden" name="authenticity_token" value="' + _silk_data.authenticity_token + '"/></form>';
    dialog.title('Please login').body(body).open();
  },
  
  formLogin: function() {
    return '<div class="silk-left">&nbsp;</div>' +
    '<div class="silk-right">' +
      '<label for="silk_login_username">Username</label>' +
      '<input type="text" id="silk_login_username" name="user[login]" value=""/>' +
      '<label for="silk_login_password">Password</label>' +
      '<input type="password" id="silk_login_password" name="user[password]" value=""/>' +
    '</div>';
  },
  
  logout: function() {
    window.location = '/logout';
    return this;
  },
 
};


/* Dialog */

silk.dialog = function(name, options) {
  this.name = name;
  this.element_id = 'silk-dialog-' + name;
  this.options = options;
  this.default_options = { modal: true, autoOpen: false, closeOnEscape: true, overlay: {backgroundColor: '#000', opacity: 0.9 } };
};
silk.dialog.prototype = {

  init: function() {
    $('body').prepend('<div id="' + this.element_id + '"></div>');
    this.element = $('#' + this.element_id);
    this.element.dialog( $.extend(this.default_options, this.options) );
    return this;
  },
  
  title: function(input) {
    $('#ui-dialog-title-' + this.element_id).html(input);
    return this;
  },
  
  body: function(input) {
    this.element.html(input);
    return this;
  },
  
  open: function() {
    this.element.dialog('open');
    return this;
  },

};


/* Dialog: Widgets */

silk.dialog.widget = function() {};
silk.dialog.widget.prototype = {
  
  confirm: function(name, title, body, buttons, form_action, form_method, form_actions) {
    var dialog_options = { width: 500, height: 205, buttons: buttons};
    var dialog = new silk.dialog(name, dialog_options).init();
    var body = '<div class="silk-dialog-padding">' + body + '</div>' +
      '<form id="silk-dialog-form-' + name + '" method="post" action="' + form_action + '">' + (form_actions || '') + '<input type="hidden" name="_method" value="' + form_method + '"/><input type="hidden" name="authenticity_token" value="' + _silk_data.authenticity_token + '"/></form>';
    dialog.title(title).body(body).open();
  },
  
  contentTypeSelector: function(obj, field_name) {
    var output = '<select name="' + field_name + '">';
    $.each(_silk_data.allowed_content_types, function() {
      output += '<option value="' + this.type + '" ' + (obj.content_type == this.type ? 'selected' : '') + '>' + this.label + '</option>';
    });
    output += '</select>';
    return output;
  },

};


/* Flash Messages */

silk.flash = function() {
  this.messages = [];
  this.flash_types = ['notice','warning','error'];
};
silk.flash.prototype = {
  
  init: function() {
    $('body').prepend('<div id="silk-flash-container" style="display: none;"></div>');
    this.container = $('#silk-flash-container');
    return this;
  },
  
  addFromPageInfo: function() { 
    var obj = this;
    $(_silk_data.flash).each(function(index, contents) {
      $(obj.flash_types).each(function() { 
        if(contents[this]) obj.messages.push({type: this, contents: contents[this]});
      });
    });
    return this;  
  },
  
  display: function() {
    var obj = this;
    $(this.messages).each(function(){
      obj.container.html('<div id="silk-flash-message" class="silk-flash-' + this.type + '">' + this.contents + '</div>').show();
      setTimeout(function(){ obj.hide() }, 3000);
    });
    return this;
  },
  
  process: function() {
    this.addFromPageInfo().display();
    return this;
  },
  
  show: function() {
    this.container.fadeIn();
    return this;
  },
  
  hide: function() {
    this.container.fadeOut();
    return this;
  }
  
};


/* Admin Menu */

silk.admin_menu = function() {
  this.buttons = {};
};
silk.admin_menu.prototype = {
  
  init: function() {
    this.renderBar().renderButtons().renderUser().renderAppButtons();
    return this;
  },
  
  renderBar: function() {
    $('body').prepend('</div><div id="silk-admin-menu">' +
      '<div id="silk-admin-menu-left"> <div id="silk-admin-menu-buttons"><ul></ul></div> </div><div id="silk-admin-menu-right"></div>' +
    '</div><div id="silk-admin-menu-spacer">');
    return this;
  },
    
  renderButtons: function() {
    
    if (Silk.page.isEditable()) {

      new silk.admin_menu.button(
        function(){ return 'Edit page' }, 
        function(){ Silk.page.edit(); }).init();
        
      if (Silk.page.path != '/')
        new silk.admin_menu.button(
        function(){ return 'Delete page' }, 
        function(){ Silk.page.destroy(); }).init();
    };

    if (Silk.page.numEditableContentAreas() > 0) {

      new silk.admin_menu.button(
        function(){ return (Silk.page.highlight_editable_elements ? 'Hide' : 'Show') + ' ' + Silk.page.numEditableContentAreas() + ' editable area' + (Silk.page.numEditableContentAreas() != '1' ? 's' : ''); },
        function(){ Silk.page.toggleHighlightEditableContent(); }).init();
    }
    
    new silk.admin_menu.button(
      function(){ return 'Logout' }, 
      function(){ Silk.user.logout(); }).init();

    return this;
  },
  
  renderUser: function() {
    $('#silk-admin-menu-right').append('<div id="silk-admin-menu-user"><a href="#" onclick="return Silk.user.logout();">owenb</a></div>');
    return this;  
  },
  
  renderAppButtons: function() {
    $('#silk-admin-menu-right').append('<div id="silk-admin-menu-app-buttons"></div>');
    $.each(Silk.apps, function() { this.renderQuickAccessIcon(); });
    return this;
  },

};


/* Admin Menu: Button */

silk.admin_menu.button = function(label, action) {
  // Note: Label and Action should both be passed as functions
  this.label = label;
  this.action = action;
  this.link = $('<a href="#"></a>');
  this.link.data('obj', this);
};
silk.admin_menu.button.prototype = {
  
  init: function() {
    $('#silk-admin-menu-buttons ul').append('<li></li>').append(this.link);
    this.render();
    return this;
  },

  render: function() {
    this.link.html(this.label()).click(this.click);
    return this;
  },
  
  click: function() {
    var obj = $(this).data('obj');
    obj.action();
    obj.render();
    return false;
  },

};


/* Apps */

silk.app = function(details) {
  $.extend(this, details);
  this.button_id = 'silk-admin-menu-app-button-' + this.app_name;
};
silk.app.prototype = {

  renderQuickAccessIcon: function () {
    $('#silk-admin-menu-app-buttons').append('<div id="' + this.button_id + '" onclick="Silk.apps.' + this.app_name + '.open(); return false;"></div>');
    $("#" + this.button_id).attr('title', this.name).
      css('background', 'url(/silk_engine/apps/'+ this.app_name + '/icons/small.png) no-repeat');
  },

},


/* Helpers */

function silk_prevent_quotes() {
  // alert(window.event.keyCode);
  if (window.event.keyCode == 222) return false;
  return true;
}


/* jQuery Extentions */

jQuery.fn.extend({
  editContents: function() {
    $(this).data('obj').edit();
  },
});


/* On Load */

$(document).ready(function() {
  Silk = new silk();
  Silk.init();
  window.onload = Silk.executeActions;
});
