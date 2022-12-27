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
        if (state == null) {
            localStorage.removeItem("loginState")
        } else {
            localStorage.setItem("loginState", JSON.stringify(state))
        }
    },

    isLogged: function () {
        const state = this.getLoginState();
        return state != null && state.username != null && state.token != null;
    },

    headers: function () {
        if (this.isLogged()) {
            const state = this.getLoginState()
            return {
                "X-AUTH-TOKEN": state.username + " " + state.token,
                "X-DEVICE": "web"
            }
        }
        return {
            "device": "web",
        }
    },

    POST: async function (requestURI, body) {
        const resp = await fetch(this.fullUrl(requestURI), {
            method: "POST",
            body: JSON.stringify(body),
            headers: this.headers(),
        })
        const ret = await resp.json()
        if (!ret.success && ret.message === "LOGIN_REQUIRED") {
            this.saveLoginState(null)
            console.log("需要登录")
        }
        return ret;
    },
}

export default API
