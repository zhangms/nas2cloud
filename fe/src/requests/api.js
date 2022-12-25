const API = {
    host: "http://localhost:8080",
    api: function (requestURI) {
        return this.host + requestURI
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
