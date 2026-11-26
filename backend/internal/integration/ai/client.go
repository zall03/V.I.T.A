package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"time"
)

type Gateway interface {
	Extract(context.Context, Request) (Result, error)
}
type Failure struct {
	Code      string
	Retryable bool
}

func (f *Failure) Error() string { return f.Code }

type Client struct {
	HTTP       *http.Client
	URL, Token string
}

func NewClient(base, token string) (*Client, error) {
	u, e := url.Parse(base)
	if e != nil || u.Host == "" || (u.Scheme != "http" && u.Scheme != "https") || u.User != nil || len(token) < 32 {
		return nil, errors.New("invalid_ai_configuration")
	}
	tr := &http.Transport{DialContext: (&net.Dialer{Timeout: 5 * time.Second}).DialContext, MaxIdleConns: 10, MaxIdleConnsPerHost: 4, IdleConnTimeout: 90 * time.Second, TLSHandshakeTimeout: 5 * time.Second, ResponseHeaderTimeout: 60 * time.Second}
	return &Client{HTTP: &http.Client{Transport: tr, Timeout: 75 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}, URL: base + "/internal/v1/clinical/extract", Token: token}, nil
}
func (c *Client) Extract(ctx context.Context, in Request) (Result, error) {
	var out Result
	if in.SchemaVersion != "1.0" || in.Transcript == "" || len(in.Transcript) > 32000 {
		return out, &Failure{"invalid_request", false}
	}
	b, e := json.Marshal(in)
	if e != nil {
		return out, e
	}
	req, e := http.NewRequestWithContext(ctx, "POST", c.URL, bytes.NewReader(b))
	if e != nil {
		return out, e
	}
	req.Header.Set("Authorization", "Bearer "+c.Token)
	req.Header.Set("Content-Type", "application/json")
	resp, e := c.HTTP.Do(req)
	if e != nil {
		return out, &Failure{"ai_unavailable", true}
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return out, &Failure{"ai_request_failed", resp.StatusCode == 429 || resp.StatusCode >= 500}
	}
	b, e = io.ReadAll(io.LimitReader(resp.Body, 128*1024+1))
	if e != nil || len(b) > 128*1024 {
		return out, &Failure{"invalid_ai_response", false}
	}
	if e = Decode(b, &out); e != nil || out.RequestID != in.RequestID || out.Status != "success" || out.SchemaVersion != "1.0" || out.PromptVersion != "clinical_extraction_v1" || !out.RequiresVerification || out.Provider == "" || out.Model == "" {
		return Result{}, &Failure{"invalid_ai_response", false}
	}
	if e = out.Data.Validate(); e != nil {
		return Result{}, &Failure{"invalid_ai_response", false}
	}
	return out, nil
}

type MockGateway struct {
	Result Result
	Err    error
}

func (m MockGateway) Extract(ctx context.Context, r Request) (Result, error) {
	v := m.Result
	v.RequestID = r.RequestID
	return v, m.Err
}
