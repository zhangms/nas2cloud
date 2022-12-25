import {createSlice} from "@reduxjs/toolkit";

const appSlice = createSlice({
    name: "app",
    initialState: {
        loginState: false,
    },
    reducers: {
        logged: function (state, action) {
            console.log("====>logged")
            return {
                loginState: true
            }
        },

        notLogged: function (state, action) {
            return {
                loginState: false
            }
        }
    }
})

export const AppReducer = appSlice.reducer
export const AppActions = appSlice.actions
