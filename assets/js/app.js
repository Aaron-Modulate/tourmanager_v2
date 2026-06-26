// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/tourmanager_v2"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: () => ({
    _csrf_token: csrfToken,
    current_tour_id: localStorage.getItem("current_tour_id") || ""
  }),
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

window.addEventListener("phx:persist_tour", (e) => {
  localStorage.setItem("current_tour_id", e.detail.tour_id)
  fetch("/api/set_tour", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-csrf-token": csrfToken
    },
    body: JSON.stringify({tour_id: e.detail.tour_id})
  })
})

// Auto-detect distance unit for new users based on timezone
window.addEventListener("phx:detect_distance_unit", () => {
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || ""
  const useMiles = tz.startsWith("America/") ||
    tz === "Europe/London" || tz.startsWith("Europe/Isle") ||
    tz === "Asia/Rangoon" || tz === "Asia/Yangon"

  fetch("/api/set_distance_unit", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-csrf-token": csrfToken
    },
    body: JSON.stringify({ distance_unit: useMiles ? "mi" : "km" })
  })
})

// Reconnection: suppress the "connection lost" banner for brief disconnects.
// LiveView's built-in reconnect handles the WebSocket; we just delay the
// error UI so backgrounding the phone doesn't flash a scary banner.
let disconnectTimer = null
const DISCONNECT_GRACE_MS = 5000

window.addEventListener("phx:page-loading-start", info => {
  if (info.detail?.kind === "error") {
    // Connection lost — start grace timer before showing error
    if (!disconnectTimer) {
      disconnectTimer = setTimeout(() => {
        document.querySelectorAll("#client-error").forEach(el => {
          el.removeAttribute("hidden")
        })
      }, DISCONNECT_GRACE_MS)
    }
    return
  }
})

window.addEventListener("phx:page-loading-stop", info => {
  // Connection restored — cancel any pending error display
  if (disconnectTimer) {
    clearTimeout(disconnectTimer)
    disconnectTimer = null
  }
  document.querySelectorAll("#client-error").forEach(el => {
    el.setAttribute("hidden", "")
  })
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

