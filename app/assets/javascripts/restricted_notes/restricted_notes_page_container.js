(function() {
  window.shared || (window.shared = {});
  var dom = window.shared.ReactHelpers.dom;
  var createEl = window.shared.ReactHelpers.createEl;
  var merge = window.shared.ReactHelpers.merge;

  var StudentProfilePage = window.shared.StudentProfilePage;
  var PropTypes = window.shared.PropTypes;
  var NotesDetails = window.shared.NotesDetails;
  var Api = window.shared.Api;

  /*
  Holds page state, makes API calls to manipulate it.
  */
  var RestrictedNotesPageContainer = window.shared.RestrictedNotesPageContainer = React.createClass({
    displayName: 'RestrictedNotesPageContainer',

    propTypes: {
      nowMomentFn: React.PropTypes.func.isRequired,
      serializedData: React.PropTypes.object.isRequired,

      // for testing
      actions: React.PropTypes.shape({
        onClickSaveNotes: React.PropTypes.func
      }),
      api: PropTypes.api
    },

    componentWillMount: function(props, state) {
      this.api = this.props.api || new Api();
    },

    getInitialState: function() {
      var serializedData = this.props.serializedData;

      return {
        // context
        currentEducator: serializedData.currentEducator,
        // constants
        educatorsIndex: serializedData.educatorsIndex,
        eventNoteTypesIndex: serializedData.eventNoteTypesIndex,
        // data
        feed: serializedData.feed,
        student: serializedData.student,
        // ui
        // This map holds the state of network requests for various actions.  This allows UI components to branch on this
        // and show waiting messages or error messages.
        // The state of a network request is described with null (no requests in-flight),
        // 'pending' (a request is currently in-flight),
        // and 'error' or another value if the request failed.
        // The keys within `request` hold either a single value describing the state of the request, or a map that describes the
        // state of requests related to a particular object.
        requests: {
          saveNote: null,
          saveService: null,
          discontinueService: {}
        }
      };
    },

    onClickSaveNotes: function(eventNoteParams) {
      // All notes taken on this page should be restricted.
      var eventNoteParams = merge(eventNoteParams, {is_restricted: true});
      this.setState({ requests: merge(this.state.requests, { saveNote: 'pending'}) });
      this.api.saveNotes(this.state.student.id, eventNoteParams)
        .done(this.onSaveNotesDone)
        .fail(this.onSaveNotesFail);
    },

    onSaveNotesDone: function(response) {
      var updatedEventNotes = this.state.feed.event_notes.concat([response]);
      var updatedFeed = merge(this.state.feed, { event_notes: updatedEventNotes });
      this.setState({
        feed: updatedFeed,
        requests: merge(this.state.requests, { saveNote: null })
      });
    },

    onSaveNotesFail: function(request, status, message) {
      this.setState({
        requests: merge(this.state.requests, { saveNote: 'error' })
      });
    },

    getNotesHelpContent: function(){
      return dom.div({},
        dom.p({}, 'Restricted Notes are only visible to the principal, AP, and guidance counselors. \
        If a note contains sensitive information about healthcare, courts, or child abuse, consider using a Restricted Note. \
        This feature is currently in development.'),
        dom.br({}),
        dom.br({}),
        dom.p({}, 'Examples include:'),
        dom.ul({},
          dom.li({}, '"Medicine change for Uri on 4/10. So far slight increase in focus."'),
          dom.li({}, '"51a filed on 3/21. Waiting determination and follow-up from DCF."')
        )
      )
    },

    render: function() {
      return dom.div({ className: 'RestrictedNotesPageContainer' },
        dom.div({ className: 'RestrictedNotesDetails', style: {display: 'flex'} },
          createEl(NotesDetails, merge(_.pick(this.state,
            'currentEducator',
            'educatorsIndex',
            'eventNoteTypesIndex',
            'feed',
            'student',
            'requests'
          ), {
            nowMomentFn: this.props.nowMomentFn,
            actions: this.props.actions || {
              onClickSaveNotes: this.onClickSaveNotes,
            },
            showingRestrictedNotes: true,
            helpContent: this.getNotesHelpContent(),
            helpTitle: 'What is a Restricted Note?',
            title: 'Restricted Notes'
          }))
        )
      );
    }
  });
})();
