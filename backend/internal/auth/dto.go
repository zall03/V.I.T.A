package auth

type LoginDTO struct {
	Email    string `json:"email" validate:"required_without=NurseID,omitempty,email,max=254"`
	NurseID  string `json:"nurse_id" validate:"required_without=Email,omitempty,uuid"`
	Password string `json:"password" validate:"required,max=128"`
}
type RefreshDTO struct {
	RefreshToken string `json:"refresh_token" validate:"required,len=43"`
}
type PasswordDTO struct {
	CurrentPassword string `json:"current_password" validate:"required,max=128"`
	NewPassword     string `json:"new_password" validate:"required,min=12,max=128"`
}
type Pair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int    `json:"expires_in"`
}
