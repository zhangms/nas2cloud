import React from 'react';
import Login from "./login/Login";
import {connect} from "react-redux";
import Main from "./main/Main";

class App extends React.Component {

    render() {
        const {isLogged} = this.props
        return (
            isLogged ? <Main/> : <Login/>
        )
    }
}

export default App = connect(function (state) {
    return {...state.App}
})(App);
