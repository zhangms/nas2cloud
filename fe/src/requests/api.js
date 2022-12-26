const API = {
    host: "http://localhost:8080",
    api: function (requestURI) {
        return this.host + requestURI
    },

    getLoginState: function () {
        const state = localStorage.getItem("loginState")
        if (state == null) {
            return null
        }
        return JSON.parse(state)
    },

    isLogged: function () {
        const state = this.getLoginState();
        return state != null && state.username != null && state.token != null;
    },

    saveLoginState: function (state) {
        if (state == null) {
            localStorage.removeItem("loginState")
        } else {
            localStorage.setItem("loginState", JSON.stringify(state))
        }
    },

    login: async function (params) {
        const resp = await fetch(this.api("/user/login"), {
            method: "POST",
            headers: {
                "device": "web"
            },
            body: JSON.stringify(params),
        })
        return await resp.json()
    }
}

export default API
