import {createSlice} from "@reduxjs/toolkit";

const fileSlice = createSlice({
    name: "fileSlice",
    initialState: {
        pageState: {
            initLoading: true,
            moreLoading: false,
        },
        data: []
    },
    reducers: {
        changeState: function (state, action) {
            let pageState = {...state.pageState, ...action.payload}
            return {
                pageState: pageState,
                data: state.data,
            }
        },

        onLoaded: function (state, action) {
            return {
                pageState: {
                    initLoading: false,
                    moreLoading: false,
                },
                data: action.payload
            }
        }
    }
})

export const FileReducer = fileSlice.reducer
export const FileActions = fileSlice.actions