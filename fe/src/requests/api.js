const API = {
    host: "http://localhost:8080",

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
        document.cookie = "X-DEVICE=web"
        document.cookie = "X-AUTH-TOKEN=" + state.username + "-" + state.token
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
                "X-DEVICE": "web"
            }
        }
        return {
            "X-DEVICE": "web",
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
