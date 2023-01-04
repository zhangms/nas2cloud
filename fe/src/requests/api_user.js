import API from "./api";

const UserApi = {
    login: async function (params) {
        return await API.POST("/api/user/login", params)
    }
}
export default UserApi
