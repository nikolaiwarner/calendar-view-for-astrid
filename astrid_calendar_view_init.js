function loadScript(link) {
  var scr = document.createElement("script");
  scr.type = "text/javascript";
  scr.src = link;
  (document.head || document.body || document.documentElement).appendChild(scr);
}

loadScript(chrome.extension.getURL("moment.min.js"));
loadScript(chrome.extension.getURL("astrid-api.js"));
loadScript(chrome.extension.getURL("fullcalendar.min.js"));
loadScript(chrome.extension.getURL("astrid_calendar_view.js"));
