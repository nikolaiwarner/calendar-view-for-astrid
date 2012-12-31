class CalendarView
  constructor: ->
    SERVER = "http://astrid.com"
    APIKEY = "bf9r3i70f5"
    SECRET = "4d9y4rmqty"
    @astrid = new Astrid(SERVER, APIKEY, SECRET)

    @sign_in()
    @build_nav()


  build_nav: =>
    $('.nav.navbar-center').append('<li><a href="javascript:;" class="launch_calendar_view">Calendar</a></li>')
    $('.launch_calendar_view').click(@show_calendar_view)


  build_calendar: =>
    html = """
    <div id="calendar_view_modal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
      <div id="calendar_view_alerts"></div>
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
        <h3 id="myModalLabel">Calendar View for Astrid</h3>
      </div>
      <div class="modal-body">
        <div class="calendar_view"></div>
        <div class="calendar_view_sign_in">
          <h2>
            Sign In to Astrid
            <small>to use Calendar View for Astrid</small>
          </h2>
          <label for="calendar_view_sign_in_username">Username</label>
          <input type="text" id="calendar_view_sign_in_username">
          <label for="calendar_view_sign_in_password">Password</label>
          <input type="password" id="calendar_view_sign_in_password">
          <br>
          <input type="submit" class="btn btn-primary" value="Sign In to Astrid" id="calendar_view_sign_in_submit">
        </div>
      </div>
    </div>
    """
    $('body').append(html)

    $('#calendar_view_sign_in_submit').click(@submit_sign_in)

    $('.calendar_view').fullCalendar
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'month,agendaWeek,agendaDay'
      aspectRatio: 2.5
      editable: true
      disableResizing: true
      events: @events
      eventDrop: @event_drop
      #dayClick: @click_day


  show_calendar_view: (e) =>
    if $('.calendar_view').length == 0
      @build_calendar()

    @update_calendar()
    $('#calendar_view_modal').modal().on 'hide', =>
      window.location = '/'


  event_drop: (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) =>
    new_timestamp = moment(event.start).unix()
    @change_task_date(event.task, new_timestamp)


  change_task_date: (task, new_timestamp)=>
    task_data =
      id: parseInt(task.id, 10)
      due: new_timestamp

    has_due_time = (new_timestamp != moment.unix(new_timestamp).sod().unix())
    if has_due_time != task.has_due_time
      task_data.has_due_time = has_due_time

    @task_save task_data, @update_calendar


  click_day: () =>


  format_date: (timestamp) =>
    moment.unix(timestamp).toDate()


  update_calendar: =>
    if @is_signed_in()
      $('.calendar_view').show()
      $('.calendar_view_sign_in').hide()

      @astrid.sendRequest 'task_list', {}, (response) =>
        tasks = response.list || []

        @events = tasks.map (task) =>
          task: task
          title: task.title
          start: @format_date(task.due)
          end: @format_date(task.due)

        #console.log "Task count:", response.list.length
        #console.log "@events", @events

        $('.calendar_view').fullCalendar('render')
    else
      $('.calendar_view').hide()
      $('.calendar_view_sign_in').show()


  events: (start, end, callback) =>
    @events ||= []
    callback(@events)


  task_save: (task, callback) =>
    @astrid.sendRequest 'task_save', task, =>
      @show_alert('Saved Task!')
      callback()


  show_alert: (message, type='success', timeout=5000) =>
    alert = """
      <div class="calendar_view_alert alert alert-#{type} fade in">
        <a href="#" class="close" data-dismiss="alert">&times;</a>
        #{message}
      </div>
    """
    alert = $(alert)
    $('#calendar_view_alerts').empty().append(alert)

    if timeout > 0
      setTimeout (=> alert.alert('close')), timeout


  submit_sign_in: =>
    username = $('#calendar_view_sign_in_username').val()
    password = $('#calendar_view_sign_in_password').val()
    @sign_in(username, password, @update_calendar, @sign_in_failure)


  sign_in_failure: (message) =>
    @show_alert(message, 'error')


  sign_in: (username, password, success, failure) =>
    token = localStorage.getItem("astrid-token")
    if token
      @astrid.setToken(token)
      success() if success
    else
      if username && password
        @astrid.signInAs username, password, ((user) =>
          localStorage.setItem "astrid-token", user.token
          success() if success
        ), failure


  sign_out: (callback) =>
    localStorage.removeItem("astrid-token")
    @astrid.setToken(undefined)
    @update_calendar()
    callback()


  is_signed_in: =>
    @astrid.isSignedIn()


$ ->
  window.calendarView = new CalendarView()
