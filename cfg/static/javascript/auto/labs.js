Event.observe(window, 'load', function() {
  var div = new Element ('div', {
    id: 'ep_labs_overlay'
  });
  var div_content = new Element ('div', {});
  var div_message = new Element ('div', {
    id: 'ep_labs_message'
  });
  var div_close = new Element ('div', {
    id: 'ep_labs_close'
  });

  div.insert (div_content);
  div_content.insert (div_message);
  div_content.insert (div_close);

  div.hide ();
  $(document.body).insert (div);

  div_close.observe ('click', function(e) {
    Effect.Fade ('ep_labs_overlay', {
      duration: .5
    });
  });

  eprints.currentRepository().phrase ({'labs_help': {}, 'labs_action_close': {}}, function(phrases) {
    div_message.insert (phrases['labs_help']);
    div_close.insert (phrases['labs_action_close']);

    Effect.Appear ('ep_labs_overlay', {
      duration: .5
    });
  });
});
