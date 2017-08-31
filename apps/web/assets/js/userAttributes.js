import React from 'react'
import { render } from "react-dom"
import Form from "react-jsonschema-form"

const attributes = window.userAttributes
const current = window.currentUserAttributes
const defaultValues = window.defaultValues

const handleSubmit = (protocol, key) => ({ formData }) => {
  $('#form').append($('<input>', {
    'name': 'params[protocol]',
    'value': protocol,
    'type': 'hidden'
  })).append($('<input>', {
    'name': 'params[key]',
    'value': key,
    'type': 'hidden'
  })).append($('<input>', {
    'name': 'params[value]',
    'value': JSON.stringify(formData),
    'type': 'hidden'
  })).append($('<input>', {
    'name': 'params[path]',
    'value': window.location.pathname,
    'type': 'hidden'
  })).submit()
}

const Field = (props) => {
  const { id, classNames, label, help, required, description, errors, children } = props
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {description}
      {children}
      {errors}
      {help}
    </div>
  )
}

const ArrayField = (props) => {
  return (
    <div>
      {props.items.map((element, i) => {
        return (
          <div key={i} className="ui grid">
            <div className="fourteen wide column">
              {element.children}
            </div>
            <div className="column">
              <button
                onClick={element.onDropIndexClick(i)}
                className="ui icon circular red button">
                <i className="remove circle icon"></i>
              </button>
            </div>
          </div>
        )
      })}
      {props.canAdd && (
        <button onClick={props.onAddClick} className="ui icon circular blue button">
          <i className="add circle icon"></i>
        </button>
      )}
    </div>
  )
}

const Forms = () => {
  const protocols = Object.keys(attributes).map(protocol => {
    const keys = Object.keys(attributes[protocol]).map(key => {
      const schema = attributes[protocol][key]
      const value = current.find(({ protocol: p, key: k }) => p == protocol && k == key)
      return (
        <div key={key} className="ui vertical segment">
          <h4>{key}</h4>
          <Form
            className="ui form"
            schema={schema}
            onSubmit={handleSubmit(protocol, key)}
            FieldTemplate={Field}
            ArrayFieldTemplate={ArrayField}
            formData={value ? value.value : defaultValues[protocol][key] || {}}
          >
            <button type="submit" className="ui primary button">Submit</button>
          </Form>
        </div>
      )
    })
    return (
      <div key={protocol} className="ui segment">
        <h3>{protocol}</h3>
        {keys}
      </div>
    )
  })
  return (
    <div>
      {protocols}
    </div>
  )
}
render((
  <Forms />
), document.getElementById("forms"))
