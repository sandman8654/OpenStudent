(function() {
  window.shared || (window.shared = {});
  var dom = window.shared.ReactHelpers.dom;
  var createEl = window.shared.ReactHelpers.createEl;
  var merge = window.shared.ReactHelpers.merge;
  var FeedHelpers = window.shared.FeedHelpers;
  var QuadConverter = window.shared.QuadConverter;
  var styles = window.shared.ProfileDetailsStyle;

  var ProfileDetails = window.shared.ProfileDetails = React.createClass({
    displayName: 'ProfileDetails',

    propTypes: {
      student: React.PropTypes.object,
      feed: React.PropTypes.object,
      access: React.PropTypes.object,
      dibels: React.PropTypes.array,
      chartData: React.PropTypes.object,
      attendanceData: React.PropTypes.object,
      serviceTypesIndex: React.PropTypes.object
    },

    getEvents: function(){
      // Returns a list of {type: ..., date: ..., value: ...} pairs, sorted by date of occurrence.
      var name = this.props.student.first_name;
      var events = [];

      _.each(this.props.attendanceData.tardies, function(obj){
        events.push({
          type: 'Tardy',
          id: obj.id,
          message: name + ' was tardy.',
          date: new Date(obj.occurred_at)
        });
      });
      _.each(this.props.attendanceData.absences, function(obj){
        events.push({
          type: 'Absence',
          id: obj.id,
          message: name + ' was absent.',
          date: new Date(obj.occurred_at)
        });
      });
      _.each(this.props.attendanceData.discipline_incidents, function(obj){
        events.push({
          type: 'Incident',
          id: obj.id,
          message: obj.incident_description + ' in the ' + obj.incident_location,
          date: new Date(obj.occurred_at)
        });
      });
      _.each(this.props.chartData.mcas_series_ela_scaled, function(quad){
        // var score = quad[3];
        events.push({
          type: 'MCAS-ELA',
          id: QuadConverter.toMoment(quad).format("MM-DD"),
          message: name + ' scored a ' + QuadConverter.toValue(quad) +' on the ELA section of the MCAS.',
          date: QuadConverter.toDate(quad)
        });
      });
      _.each(this.props.chartData.mcas_series_math_scaled, function(quad){
        // var score = quad[3];
        events.push({
          type: 'MCAS-Math',
          id: QuadConverter.toMoment(quad).format("MM-DD"),
          message: name + ' scored a ' + QuadConverter.toValue(quad) +' on the Math section of the MCAS.',
          date: QuadConverter.toDate(quad)
        });
      });
      _.each(this.props.chartData.star_series_reading_percentile, function(quad){
        // var score = quad[3];
        events.push({
          type: 'STAR-Reading',
          id: QuadConverter.toMoment(quad).format("MM-DD"),
          message: name + ' scored in the ' + QuadConverter.toValue(quad) +'th percentile on the Reading section of STAR.',
          date: QuadConverter.toDate(quad)
        });
      });
      _.each(this.props.chartData.star_series_math_percentile, function(quad){
        // var score = quad[3];
        events.push({
          type: 'STAR-Math',
          id: QuadConverter.toMoment(quad).format("MM-DD"),
          message: name + ' scored in the ' + QuadConverter.toValue(quad) +'th percentile on the Math section of STAR.',
          date: QuadConverter.toDate(quad)
        });
      });
      _.each(this.props.feed.deprecated.interventions, function(obj){
        events.push({
          type: 'Note',
          id: obj.id,
          message: obj.name + '(Goal: ' + obj.goal + ')',
          date: moment(obj.start_date_timestamp, "YYYY-MM-DD").toDate()
        });
      });
      _.each(this.props.feed.deprecated.notes, function(obj){
        events.push({
          type: 'Note',
          id: obj.id,
          message: obj.content,
          date: moment(obj.created_at_timestamp).toDate()
        });
      });
      _.each(this.props.feed.event_notes, function(obj){
        events.push({
          type: 'Note',
          id: obj.id,
          message: obj.text,
          date: moment(obj.recorded_at).toDate()
        });
      });

      var services = this.props.feed.services.active.concat(this.props.feed.services.discontinued);
      _.each(services, function(obj){
        events.push({
          type: 'Service',
          id: obj.id,
          message: this.getMessageForServiceType(obj.service_type_id),
          date: moment(obj.date_started).toDate()
        })
      }.bind(this));

      _.each(this.props.dibels, function(obj) {
        // TODO(kr) need to investigate further, whether this is local demo data or production
        // data quality issue
        if (obj.performance_level === null) return;

        var cleanedDate = obj.date_taken.split('T')[0];
        var parsedDate = moment(cleanedDate).toDate();

        events.push({
          type: 'DIBELS',
          id: obj.id,
          message: name + ' scored ' + obj.performance_level.toUpperCase() + ' in DIBELS.',
          date: parsedDate
        });
      });
      return _.sortBy(events, 'date').reverse();
    },

    onClickGenerateSpedReferral: function(event) {
      window.location = this.props.student.id + '/sped_referral.pdf';
      return null;
    },

    render: function(){
      return dom.div({},
        this.renderAccessDetails(),
        this.renderFullCaseHistory()
      )
    },

    renderAccessDetails: function () {
      var access = this.props.access;
      if (!access) return null;

      var access_result_rows = Object.keys(access).map(function(subject) {
        return dom.tr({ key: subject },
          dom.td({ style: styles.accessLeftTableCell }, subject),
          dom.td({}, access[subject] || '—')
        );
      });

      return dom.div({},
        dom.h4({style: styles.title}, 'ACCESS'),
        dom.table({},
          dom.thead({},
            dom.tr({},
              dom.th({ style: styles.accessTableHeader }, 'Subject'),
              dom.th({ style: styles.accessTableHeader }, 'Score')
            )
          ),
          dom.tbody({}, access_result_rows)
        ),
        dom.div({}),
        dom.div({ style: styles.accessTableFootnote }, 'Most recent ACCESS scores shown.')
      );
    },

    renderFullCaseHistory: function(){
      var self = this;
      var bySchoolYearDescending = _.toArray(
        _.groupBy(this.getEvents(), function(event){ return QuadConverter.toSchoolYear(event.date) })
      ).reverse();

      return dom.div({id: "full-case-history"},
        dom.div({ className: 'ServicesHeader', style: styles.fullCaseHistoryHeading },
          dom.h4({style: styles.fullCaseHistoryTitle}, 'Full Case History'),
          dom.button({
            className: 'btn btn-warning',
            style: styles.spedButton,
            onClick: this.onClickGenerateSpedReferral
          }, 'BETA: Generate SPED Referral')
        ),
        bySchoolYearDescending.map(this.renderCardsForYear)
      );
    },

    renderCardsForYear: function(eventsForYear){
      // Grab what school year we're in from any object in the list.
      var year = QuadConverter.toSchoolYear(eventsForYear[0].date);
      // Computes '2016 - 2017 School Year' for input 2016, etc.
      var schoolYearString = year.toString() + ' - ' + (year+1).toString() + ' School Year';

      var key = 'school-year-starting-' + year;
      return dom.div(
        {style: styles.box, key: key, id: key},
        dom.h4({style: styles.schoolYearTitle}, schoolYearString),
        eventsForYear.map(this.renderCard)
      )
    },

    renderCard: function(event){
      var key = [event.type, event.id].join("-");

      if (event.type === 'Absence' || event.type === 'Tardy'){
        // These event types are less important, so make them smaller and no description text.
        var containingDivStyle = styles.feedCard;
        var headerDivStyle = merge(styles.feedCardHeader, {fontSize: 14});
        var paddingStyle = {paddingLeft: 10};
        var text = '';
      } else {
        var containingDivStyle = merge(styles.feedCard, {border: '1px solid #eee'});
        var headerDivStyle = styles.feedCardHeader;
        var paddingStyle = {padding: 10};
        var text = event.message;
      }

      var dateStyle = {display: 'inline-block', width: 180};

      var badgeStyle = merge(styles.badge, {background: styles.type_to_color[event.type]});

      return dom.div({key: key, id: key, style: containingDivStyle},
        dom.div({style: paddingStyle},
          dom.div({style: headerDivStyle},
            dom.span({style: dateStyle}, this.displayEventDate(event.date)),
            dom.span({style: badgeStyle}, event.type.replace("-", " "))
          ),
        text
        )
      );
    },

    displayEventDate: function(event_date){
      // Use UTC to avoid timezone-related display errors. (See GitHub issue #622.)
      // Timezone is irrelevant for this UI. We are not displaying times, only dates.

      return moment(event_date).utc().format("MMMM Do, YYYY:");
    },

    getMessageForServiceType: function(service_type_id){
      // Given a service_type_id, returns a message suitable for human consumption describing the service.
      var lookup = this.props.serviceTypesIndex;
      if (lookup.hasOwnProperty(service_type_id)){
        var text = lookup[service_type_id].name;
      } else {
        var text = "Description not found for code: " + service_type_id;
      }

      return text;
    }

  });
})();
