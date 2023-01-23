function getApiHost() {
    const href = document.location.href
    if (href.startsWith("http://localhost:3000")) {
        return "http://localhost:8080";
    }
    return "";
}

const API = {
    host: getApiHost(),

    fullUrl: function (requestURI) {
        return this.host + requestURI
    },

    getLoginState: function () {
        const state = localStorage.getItem("loginState")
        if (state == null) {
            return null
        }
        return JSON.parse(state)
    },

    saveLoginState: function (state) {
        localStorage.setItem("loginState", JSON.stringify(state))
        document.cookie = "X-DEVICE=react-console; path=/"
        document.cookie = "X-AUTH-TOKEN=" + state.username + "-" + state.token + "; path=/"
    },

    clearLoginState: function () {
        localStorage.removeItem("loginState")
        document.cookie = ""
    },

    isLogged: function () {
        const state = this.getLoginState();
        return state != null && state.username != null && state.token != null;
    },

    headers: function () {
        if (this.isLogged()) {
            const state = this.getLoginState()
            return {
                "X-AUTH-TOKEN": state.username + "-" + state.token,
                "X-DEVICE": "react-console"
            }
        }
        return {
            "X-DEVICE": "react-console",
        }
    },

    POST: async function (requestURI, body) {
        const resp = await fetch(this.fullUrl(requestURI), {
            method: "POST",
            body: JSON.stringify(body),
            headers: this.headers(),
            credentials: "same-origin"
        })
        const ret = await resp.json()
        if (!ret.success && ret.message === "LOGIN_REQUIRED") {
            this.clearLoginState()
        }
        return ret;
    },
}

export default API
