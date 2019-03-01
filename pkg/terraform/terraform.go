package terraform

import (
	"bufio"
	"io/ioutil"

	"github.com/deislabs/porter-terraform/pkg/kubernetes"
	"github.com/deislabs/porter/pkg/context"
	"github.com/pkg/errors"
	k8s "k8s.io/client-go/kubernetes"
)

// terraform is the logic behind the terraform mixin
type Mixin struct {
	*context.Context
	ClientFactory kubernetes.ClientFactory
}

// New terraform mixin client, initialized with useful defaults.
func New() *Mixin {
	return &Mixin{
		Context:       context.New(),
		ClientFactory: kubernetes.New(),
	}
}

func (m *Mixin) getPayloadData() ([]byte, error) {
	reader := bufio.NewReader(m.In)
	data, err := ioutil.ReadAll(reader)
	return data, errors.Wrap(err, "could not read the payload from STDIN")
}

func (m *Mixin) getKubernetesClient(kubeconfig string) (k8s.Interface, error) {
	return m.ClientFactory.GetClient(kubeconfig)
}
