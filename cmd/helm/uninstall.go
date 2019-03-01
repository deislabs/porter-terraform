package main

import (
	"github.com/deislabs/porter-helm/pkg/helm"
	"github.com/spf13/cobra"
)

func buildUninstallCommand(m *helm.Mixin) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "uninstall",
		Short: "Execute the uninstall functionality of this mixin",
		RunE: func(cmd *cobra.Command, args []string) error {
			return m.Uninstall()
		},
	}
	return cmd
}
