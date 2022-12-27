import API from "./api";

const UserApi = {
    login: async function (params) {
        return await API.POST("/user/login", params)
    }
}
export default UserApi
