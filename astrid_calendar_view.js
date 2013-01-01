// Generated by CoffeeScript 1.3.1
(function() {
  var CalendarView,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  CalendarView = (function() {

    CalendarView.name = 'CalendarView';

    function CalendarView() {
      this.is_signed_in = __bind(this.is_signed_in, this);

      this.sign_out = __bind(this.sign_out, this);

      this.sign_in = __bind(this.sign_in, this);

      this.sign_in_failure = __bind(this.sign_in_failure, this);

      this.submit_sign_in = __bind(this.submit_sign_in, this);

      this.show_alert = __bind(this.show_alert, this);

      this.task_save = __bind(this.task_save, this);

      this.events = __bind(this.events, this);

      this.set_task_css = __bind(this.set_task_css, this);

      this.update_calendar = __bind(this.update_calendar, this);

      this.format_date = __bind(this.format_date, this);

      this.click_day = __bind(this.click_day, this);

      this.change_task_date = __bind(this.change_task_date, this);

      this.event_drop = __bind(this.event_drop, this);

      this.show_calendar_view = __bind(this.show_calendar_view, this);

      this.build_calendar = __bind(this.build_calendar, this);

      this.build_nav = __bind(this.build_nav, this);

      var APIKEY, SECRET, SERVER;
      SERVER = "http://astrid.com";
      APIKEY = "bf9r3i70f5";
      SECRET = "4d9y4rmqty";
      this.astrid = new Astrid(SERVER, APIKEY, SECRET);
      this.sign_in();
      this.build_nav();
    }

    CalendarView.prototype.build_nav = function() {
      $('.nav.navbar-center').append('<li><a href="javascript:;" class="launch_calendar_view">Calendar</a></li>');
      return $('.launch_calendar_view').click(this.show_calendar_view);
    };

    CalendarView.prototype.build_calendar = function() {
      var html;
      html = "<div id=\"calendar_view_modal\" class=\"modal hide fade\" tabindex=\"-1\" role=\"dialog\" aria-labelledby=\"myModalLabel\" aria-hidden=\"true\">\n  <div id=\"calendar_view_alerts\"></div>\n  <div class=\"modal-header\">\n    <span data-dismiss=\"modal\" aria-hidden=\"true\" class=\"pull-right\">Close</span>\n    <span id=\"calendar_view_sign_out_submit\" class=\"pull-right\">Sign Out</span>\n    <h3 id=\"myModalLabel\">Calendar View for Astrid</h3>\n  </div>\n  <div class=\"modal-body\">\n    <div class=\"calendar_view\"></div>\n    <div class=\"calendar_view_sign_in\">\n      <h2>\n        Sign In to Astrid\n        <small>to use Calendar View for Astrid</small>\n      </h2>\n      <label for=\"calendar_view_sign_in_username\">Username</label>\n      <input type=\"text\" id=\"calendar_view_sign_in_username\">\n      <label for=\"calendar_view_sign_in_password\">Password</label>\n      <input type=\"password\" id=\"calendar_view_sign_in_password\">\n      <br>\n      <input type=\"submit\" class=\"btn btn-primary\" value=\"Sign In to Astrid\" id=\"calendar_view_sign_in_submit\">\n    </div>\n  </div>\n</div>";
      $('body').append(html);
      $('#calendar_view_sign_in_submit').click(this.submit_sign_in);
      $('#calendar_view_sign_out_submit').click(this.sign_out);
      return $('.calendar_view').fullCalendar({
        header: {
          left: 'prev,next today',
          center: 'title',
          right: 'month,agendaWeek,agendaDay'
        },
        aspectRatio: 2.5,
        editable: true,
        disableResizing: true,
        allDayText: 'Any time',
        events: this.events,
        eventDrop: this.event_drop
      });
    };

    CalendarView.prototype.show_calendar_view = function(e) {
      var _this = this;
      if ($('.calendar_view').length === 0) {
        this.build_calendar();
      }
      this.update_calendar();
      return $('#calendar_view_modal').modal().on('hide', function() {
        return window.location = '/';
      });
    };

    CalendarView.prototype.event_drop = function(event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) {
      var new_timestamp;
      new_timestamp = moment(event.start).unix();
      return this.change_task_date(event.task, new_timestamp, revertFunc);
    };

    CalendarView.prototype.change_task_date = function(task, new_timestamp, failure) {
      var has_due_time, task_data;
      task_data = {
        id: parseInt(task.id, 10),
        due: new_timestamp
      };
      has_due_time = new_timestamp !== moment.unix(new_timestamp).sod().unix();
      if (has_due_time !== task.has_due_time) {
        task_data.has_due_time = has_due_time;
      }
      return this.task_save(task_data, this.update_calendar, failure);
    };

    CalendarView.prototype.click_day = function() {};

    CalendarView.prototype.format_date = function(timestamp) {
      return moment.unix(timestamp).toDate();
    };

    CalendarView.prototype.update_calendar = function() {
      var _this = this;
      if (this.is_signed_in()) {
        $('.calendar_view').show();
        $('.calendar_view_sign_in').hide();
        $('#calendar_view_sign_out_submit').show();
        return this.astrid.sendRequest('task_list', {}, function(response) {
          var tasks;
          tasks = response.list || [];
          _this.events = tasks.map(function(task) {
            var hash;
            hash = {
              task: task,
              title: task.title,
              start: _this.format_date(task.due),
              end: _this.format_date(task.due + 1500)
            };
            hash = _this.set_task_css(hash);
            if (task.has_due_time) {
              hash.allDay = false;
            }
            return hash;
          });
          return $('.calendar_view').fullCalendar('render');
        });
      } else {
        $('.calendar_view').hide();
        $('.calendar_view_sign_in').show();
        return $('#calendar_view_sign_out_submit').hide();
      }
    };

    CalendarView.prototype.set_task_css = function(hash, classnames) {
      if (classnames == null) {
        classnames = [];
      }
      if (hash.start < moment().sod().toDate()) {
        classnames.push('overdue');
      }
      hash.className = classnames;
      return hash;
    };

    CalendarView.prototype.events = function(start, end, callback) {
      this.events || (this.events = []);
      return callback(this.events);
    };

    CalendarView.prototype.task_save = function(task, success, failure) {
      var _this = this;
      return this.astrid.sendRequest('task_save', task, (function() {
        _this.show_alert('Saved Task!');
        if (success) {
          return success();
        }
      }), function() {
        _this.show_alert('Task could not be saved.', 'error');
        if (failure) {
          return failure();
        }
      });
    };

    CalendarView.prototype.show_alert = function(message, type, timeout) {
      var alert,
        _this = this;
      if (type == null) {
        type = 'success';
      }
      if (timeout == null) {
        timeout = 5000;
      }
      alert = "<div class=\"calendar_view_alert alert alert-" + type + " fade in\">\n  <a href=\"#\" class=\"close\" data-dismiss=\"alert\">&times;</a>\n  " + message + "\n</div>";
      alert = $(alert);
      $('#calendar_view_alerts').empty().append(alert);
      if (timeout > 0) {
        return setTimeout((function() {
          return alert.alert('close');
        }), timeout);
      }
    };

    CalendarView.prototype.submit_sign_in = function() {
      var password, username;
      username = $('#calendar_view_sign_in_username').val();
      password = $('#calendar_view_sign_in_password').val();
      return this.sign_in(username, password, this.update_calendar, this.sign_in_failure);
    };

    CalendarView.prototype.sign_in_failure = function(message) {
      return this.show_alert(message, 'error');
    };

    CalendarView.prototype.sign_in = function(username, password, success, failure) {
      var token,
        _this = this;
      token = localStorage.getItem("astrid-token");
      if (token) {
        this.astrid.setToken(token);
        if (success) {
          return success();
        }
      } else {
        if (username && password) {
          return this.astrid.signInAs(username, password, (function(user) {
            localStorage.setItem("astrid-token", user.token);
            if (success) {
              return success();
            }
          }), failure);
        }
      }
    };

    CalendarView.prototype.sign_out = function(callback) {
      localStorage.removeItem("astrid-token");
      this.astrid.setToken(void 0);
      this.update_calendar();
      if (callback) {
        return callback();
      }
    };

    CalendarView.prototype.is_signed_in = function() {
      return this.astrid.isSignedIn();
    };

    return CalendarView;

  })();

  $(function() {
    return window.calendarView = new CalendarView();
  });

}).call(this);
