class CalendarView
  constructor: ->
    SERVER = "https://astrid.com"
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
        <span data-dismiss="modal" aria-hidden="true" class="btn pull-right">Close</span>
        <span id="calendar_view_sign_out_submit" class="pull-right">Sign Out</span>
        <!--<span class="pull-right"><a href="https://chrome.google.com/webstore/support/kmddbiagkpdgldeekdakkodcfhfagdhi?hl=en&gl=US" target="_blank">Feedback</a></span>
        -->
        <h3 id="myModalLabel">Calendar View for Astrid</h3>
      </div>
      <div class="modal-body">
        <div class="calendar_view"></div>
        <div class="calendar_view_sign_in">
          <div class="row-fluid">
            <div class="span6">
              <h2>
                Sign In to Astrid
                <small>to use Calendar View for Astrid</small>
              </h2>
              <label for="calendar_view_sign_in_username">Email Address</label>
              <input type="text" id="calendar_view_sign_in_username">
              <label for="calendar_view_sign_in_password">Password</label>
              <input type="password" id="calendar_view_sign_in_password">
              <br>
              <input type="submit" class="btn btn-primary" value="Sign In to Astrid" id="calendar_view_sign_in_submit">
            </div>
            <div class="span6">
              <div class="well">
                <p>
                  Calendar View for Astrid uses your Astrid.com email address and password to log in. If you typically connect with Astrid using Facebook or Google, you will need to make an Astrid.com password in order to sign in.
                </p>
                <p>
                  Need to set or forgot your Astrid.com password?
                  <br/>
                  <input type="text" id="calendar_view_reset_password_email" placeholder="Your Email Address">
                  <br>
                  <a class="btn" id="calendar_view_password_reset_button">Send Password Reset</a>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
    $('body').append(html)

    $('#calendar_view_sign_in_submit').click @submit_sign_in
    $('#calendar_view_sign_out_submit').click @sign_out
    $('#calendar_view_password_reset_button').click @send_password_reset

    $('.calendar_view').fullCalendar
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'month,agendaWeek,agendaDay'
      aspectRatio: 2.5
      editable: true
      disableResizing: true
      allDayText: 'Any time'
      events: @events
      eventDrop: @event_drop
      #dayClick: @click_day


  show_calendar_view: (e) =>
    if $('.calendar_view').length == 0
      @build_calendar()

    @update_calendar()
    $('#calendar_view_modal').modal().on 'hide', =>
      # hack to refresh Astrid's page
      window.location = '/'


  event_drop: (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) =>
    new_timestamp = moment(event.start).unix()
    @change_task_date(event.task, new_timestamp, revertFunc)


  change_task_date: (task, new_timestamp, failure)=>
    task_data =
      id: task.id
      due: new_timestamp

    has_due_time = (new_timestamp != moment.unix(new_timestamp).sod().unix())
    if has_due_time != task.has_due_time
      task_data.has_due_time = has_due_time

    @task_save task_data, @update_calendar, failure


  complete_task: (task, failure) =>
    task_data =
      id: task.id
      completed_at: Date.now()
    @task_save task_data, @update_calendar, failure


  click_day: () =>


  format_date: (timestamp) =>
    moment.unix(timestamp).toDate()


  update_calendar: =>
    if @is_signed_in()
      $('.calendar_view').show()
      $('.calendar_view_sign_in').hide()
      $('#calendar_view_sign_out_submit').show()

      @astrid.sendRequest 'task_list', {}, (response) =>
        tasks = response.list || []

        @events = tasks.map (task) =>
          hash =
            task: task
            title: task.title
            start: @format_date(task.due)
            end: @format_date(task.due + 1500) # ends at time + one pomodoro

          hash = @set_task_css(hash)

          if task.has_due_time
            hash.allDay = false

          return hash

        #console.log "Task count:", response.list.length
        #console.log "@events", @events

        $('.calendar_view').fullCalendar('render')
    else
      $('.calendar_view').hide()
      $('.calendar_view_sign_in').show()
      $('#calendar_view_sign_out_submit').hide()


  set_task_css: (hash, classnames=[]) =>
    if hash.start < moment().sod().toDate()
      classnames.push('overdue')

    hash.className = classnames
    return hash


  events: (start, end, callback) =>
    @events ||= []
    callback(@events)


  task_save: (task, success, failure) =>
    @astrid.sendRequest 'task_save', task, (response) =>
      if response.status != 'failure'
        @show_alert('Saved Task!')
        success() if success
      else
        @show_alert("Task could not be saved. #{response.message}", 'error')
        failure() if failure


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
    callback() if callback


  is_signed_in: =>
    @astrid.isSignedIn()


  send_password_reset: =>
    hash =
      email: $('#calendar_view_reset_password_email').val()
    @astrid.sendRequest 'user_reset_password', hash, (response) =>
      if response.status == 'success'
        $('#calendar_view_reset_password_email').val('')
        @show_alert 'Astrid.com password reset link sent! Please check your email.'
      else
        @show_alert response.message, 'error'

$ ->
  window.calendarView = new CalendarView()
