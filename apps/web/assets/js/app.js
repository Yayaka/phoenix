import "../css/app.css" // omg
import "phoenix_html"
import {Socket} from "phoenix"

const timeline = $("#timeline");
function addEvent(event) {
  let item = $("<div class=\"item\"></div>").text(JSON.stringify(event))
  timeline.append(item)
}

if (window.timelineToken) {
  let socket = new Socket("/socket", {params: {token: window.timelineToken}})
  socket.connect()
  let channel = socket.channel("timeline", {})
  channel.join()
    .receive("ok", events => {
      console.log("Joined successfully", events)
      events.forEach(event => {
        addEvent(event)
      })
    })
    .receive("error", resp => { console.log("Unable to join", resp) })
  channel.on("push_event", ({ event }) => {
    addEvent(event)
  })
  $("#event").submit(event => {
    event.preventDefault()
    let repository_host = $("#repository_host").val()
    let protocol = $("#protocol").val()
    let type = $("#type").val()
    let body = JSON.parse($("#body").val())
    channel.push("create_event", {
      repository_host,
      event: {
        protocol, type, body
      }
    })
  })
}
