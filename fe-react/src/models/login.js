import {createSlice} from "@reduxjs/toolkit";

const loginSlice = createSlice({
    name: "login",
    initialState: {
        errorDisplay: "none",
        errorMessage: ""
    },
    reducers: {
        closeError: function (state, action) {
            return {
                errorDisplay: "none",
            }
        },

        showError: function (state, action) {
            const payload = action.payload
            return {
                errorDisplay: "",
                errorMessage: payload.message
            }
        }
    }
})

export const LoginReducer = loginSlice.reducer
export const LoginActions = loginSlice.actions
