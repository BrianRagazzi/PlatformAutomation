uaac token owner get opsman admin -p VMware1! -s ""

ACCESS_TOKEN=$(uaac context | grep access_token: | cut -d ":" -f2)

eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vb20ucGtzLnJhZ2F6emlsYWIuY29tOjQ0My91YWEvdG9rZW5fa2V5cyIsImtpZCI6ImtleS0xIiwidHlwIjoiSldUIn0.eyJqdGkiOiI4MzQ1YjVjY2MxYjM0NWM5ODZjMGZhZDE2N2UwNDYwMSIsInN1YiI6IjkzOWRiNmNlLWIwNGUtNGVhYy05YzdmLWJiNjdhYjBlOGYyNiIsInNjb3BlIjpbIm9wc21hbi5hZG1pbiIsInNjaW0ubWUiLCJ1YWEuYWRtaW4iLCJjbGllbnRzLmFkbWluIl0sImNsaWVudF9pZCI6Im9wc21hbiIsImNpZCI6Im9wc21hbiIsImF6cCI6Im9wc21hbiIsImdyYW50X3R5cGUiOiJwYXNzd29yZCIsInVzZXJfaWQiOiI5MzlkYjZjZS1iMDRlLTRlYWMtOWM3Zi1iYjY3YWIwZThmMjYiLCJvcmlnaW4iOiJ1YWEiLCJ1c2VyX25hbWUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW5AdGVzdC5vcmciLCJhdXRoX3RpbWUiOjE1NTgwMTUyOTEsInJldl9zaWciOiJiZWQ2NmJlNSIsImlhdCI6MTU1ODAxNTI5MSwiZXhwIjoxNTU4MDU4NDkxLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvdWFhL29hdXRoL3Rva2VuIiwiemlkIjoidWFhIiwiYXVkIjpbInNjaW0iLCJvcHNtYW4iLCJjbGllbnRzIiwidWFhIl19.MFwJIUn4OGbt6yxVzqaR_u1vySvWBRYENU0em5dnW9j9_dYPgipKaeA---BkQfR3b86yTMTUlvQQ9tchywI0QV0vxPH_8EJMoRxVykOD0ScbckrLxd3FQ2JiOLkk3DuVw25w4fVhl2STq-hN1SeRKEVowR3RLZ2vwW604XmJd2IxolXY1VtCp6gzQ7O_zMm4x9KaeRT8ViGgFzyEtL-QMLxZHMA72hX5cdItGaobuxbcIKvsN4PKRPqhOQ7pMcb7ltrSpcM7SGvis-LknqPlMvTco7CAG1a7NDqJQYWAednFsHjyEx5RBrXCESk_MqwaC8U8xZyybPfR1zX68EvITA


curl -k -H "Authorization: Bearer ${echo $ACCESS_TOKEN}" https://om.pks.ragazzilab.com/api/v0/deployed/director/credentials/director_credentials
